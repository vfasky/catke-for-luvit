-- 初始化
local os         = require('os')
local http       = require('http')
local timer      = require('timer')
local Array      = require('catke/base').Array
local htmlparser = require('htmlparser')
local JSON       = require('json')
local twisted    = require('twisted')
local models     = require('../models')

local yield = twisted.yield

local Article        = models.Article
local Keyword        = models.Keyword
local ArticleKeyword = models.ArticleKeyword

local _init_task = false
local _link_list = Array:new()

local get_hot_comment = function(id)
	local html = ''
	local req  = http.request({
		host = "m.cnbeta.com",
		port = 80,
		path = "/hotcomments.htm?id=" .. id
	}, function (res)
		res:on('error', function(msg)
			res:destroy()
		end)

		res:on('data', function (chunk)
			html = html .. chunk	
		end)
		res:on("end", function ()
			local list     = Array:new()
			local root     = htmlparser.parse(html)
			local elements = root('.content')
		
			for e in pairs(elements) do
				local html = e:getcontent()
				local html_arr = Array:new(html:split("%<%/div%>"))
				
				if html_arr:length() > 3 then
					
					if 1 ~= html_arr:get(3):find('第') then
						return
					end
					local ix = 0;
					local user       = Array:new()
					local date       = Array:new()
					local comment    = Array:new()
					local support    = Array:new()
					local opposition = Array:new()
					html_arr:remove(html_arr:get(1))
					html_arr:remove(html_arr:get(2))

					html_arr:each(function(txt)
						if txt:find('第') == 1 then
							ix = 0
						end
						ix = ix + 1
						if ix == 4 then
							local tmp = txt:split(' ')
							--p(tmp[#tmp])
							user:append(tmp[1])
							date:append(tmp[#tmp])
						
						elseif ix == 6 then
							comment:append(txt:trim())
						
						elseif ix == 13 then
							local tmp = txt:split(':')

							local status, err = pcall(function()
								support:append(tonumber(tmp[1]:sub(2, tmp[1]:find(')') - 1 )))
								opposition:append(tonumber(tmp[2]:sub(2,-2)))

							end)

							if not status then
								support:append(0)
								opposition:append(0)

							end
						
						end

					end)

					comment:each(function(data, k)
						local item = {
							user       = user:get(k),
							date       = date:get(k),
							comment    = data,
							support    = support:get(k),
							opposition = opposition:get(k),
						}
						list:append(item)
					end)
				
				end
			end
			
			if list:length() > 0 then
				Article:select():where(Article.cid.Eq(id)):get(function(ar)
					if ar then
						ar.comment = JSON.stringify(list())
						ar:save(function() end)
						--p(ar)
					end
				end)
			end

			res:destroy()
		end)

	end)
	req:done()
end


local get_article = function(id, task_queue)
	local html = ''
	local req  = http.request({
		host = "catke.eu01.aws.af.cm",
		port = 80,
		path = "/?url=http://m.cnbeta.com/view.htm?id=" .. id
	}, function (res)
		res:on('data', function (chunk)
			html = html .. chunk	
			--p(html)
		end)
		res:on('error', function(msg)
			res:destroy()
		end)
		res:on("end", function ()
			if html:find('{') == 1 then
				local data = JSON.parse(html)

				if data['success'] then
					local async = twisted.inline_callbacks(function()
						local article = yield(function(gen)
							Article:select():where(Article.cid.Eq(id)):get(gen)
						end)
						
						if nil == article then
							--p('creat')	
						
							-- save
							article = yield(function(gen)
								local article = Article({
									cid = id,
									title = data['title'],
									time = os.time(), 
									summarize = JSON.stringify(data['summarizes']),
									content = data['html'],
								})

								--p(article.id)
								--return

								article:save(gen)
							end)

							
							if not article or nil == article.id then
								return 
							end

							-- 保存关键字
							local keywords = Array:new(data['keyword'])

							keywords:each(function(kw)
								local keyword = yield(function(gen)
									Keyword:select():where(Keyword.title.Eq(kw)):get(gen)
								end)


								if nil == keyword then
									keyword = Keyword({
										title = kw
									})

									keyword = yield(function(gen)
										keyword:save(gen)
									end)
								end

								if nil == keyword then
									return
								end

								local hasid = article.id .. '-' .. keyword.id
								
								-- 关联文章
								local count = yield(function(gen)
									ArticleKeyword:select()
									              :where(ArticleKeyword.hasid.Eq(hasid))
												  :count(gen)
								end)

								if 0 == count then
									--p(article)
									--p(keyword)
									local artkw = ArticleKeyword({
										article = article.id,
										keyword = keyword.id,
										hasid   = hasid,
									})

									--p(artkw)
									local status, err = pcall(function()
										artkw:save(function(artkw)
											--p(artkw)
										end)
									end)
								end


							end)

							-- get comment

							task_queue.add({
								time = 10,
								callback = function()	
									p('get comment : ' .. id)
									get_hot_comment(id)
									--get_article(id, task_queue)
								end
							})

						end
					end)

					async()
				end
				--p(data['success'])
				--p(data['title'])
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
			--p(id)
			list:append(data[2])
			if -1 == _link_list:index(id) then
				count = count + 1
				local task = function(ix, id)
					task_queue.add({
						time = 10 * ix,
						callback = function()	
							p('get : ' .. id)
							get_article(id, task_queue)
						end
					})

				end
				
				task(count, id)
			else
				task_queue.add({
					time = 300,
					callback = function()
						p('get comment : ' .. id)
						get_hot_comment(id)
					end
				})
				
			end
		end
	end

	_link_list = list
end

return function (req, res, app, gen)
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
				res:on('error', function(msg)
					res:destroy()
				end)

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

		--get_article(254843, app.task_queue)
		get_list()
		
		app.task_queue.add({
			time = 300,
			count = -1,
			callback = get_list
		})

	end


	gen(true)
end
