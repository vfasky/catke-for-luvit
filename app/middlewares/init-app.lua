-- 初始化
local os         = require('os')
local http       = require('http')
local timer      = require('timer')
local Array      = require('catke/base').Array
local htmlparser = require('htmlparser')
local JSON       = require('json')
local _init_task = false

local _link_list = Array:new()

local get_article = function(id, task_queue)
	local html = ''
	local req  = http.request({
		host = "catke.eu01.aws.af.cm",
		port = 80,
		path = "/?url=http://m.cnbeta.com/view.htm?id=" .. id
	}, function (res)
		res:on('data', function (chunk)
			html = html .. chunk	
		end)
		res:on("end", function ()
			if html:find('{') == 1 then
				local data = JSON.parse(html)
				p(data['success'])
				p(data['title'])
			end
						
			res:destroy()
		end)
	end)
	req:done()
end


-- 格式化 m.cnbeta.com
local format_list = function(html, task_queue)
	local e
	local list     = Array:new()
	local root     = htmlparser.parse(html)
	local elements = root('.list a')
	local count    = 0
		
	for e in pairs(elements) do
		local data = e.attributes['href']:split('=')
		local id   = data[2]
		if id then
			list:append(data[2])
			if -1 == _link_list:index(id) then
				count = count + 1
				local task = function(ix, id)
					task_queue.add({
						time = 5 * ix,
						callback = function()	
							p('get : ' .. id)
							get_article(id, task_queue)
						end
					})

				end
				
				task(count, id)
				
			end
		end
	end

	_link_list = list
end

return function (req, res, handlers, app)
	req.run_time = os.time()

	if false == _init_task then
		_init_task = true

		local get_list = function()
			local html = ''
			local req  = http.request({
				host = "m.cnbeta.com",
			 	port = 80,
			 	path = "/"
			}, function (res)
				res:on('data', function (chunk)
					html = html .. chunk	
					--p('add')
				end)
				res:on("end", function ()
					format_list(html, app.task_queue)
					--p('end')
					res:destroy()
				end)
			end)
						
			req:done()
		end
		
		app.task_queue.add({
			time = 5,
			count = 3,
			callback = get_list
		})

	end


	return handlers 
end
