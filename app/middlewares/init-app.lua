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

				if data['success'] then
					local async = twisted.inline_callbacks(function()
						local count = yield(function(gen)
							Article:select():where(Article.cid.Eq(id)):count(gen)
						end)
						
						if 0 == count then
							article = Article({
								cid = id,
								title = data['title'],
								summarize = JSON.stringify(data['summarizes']),
								content = data['html'],
							})
							
							-- save
							article = yield(function(gen)
								article:save(gen)
							end)

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

								
								-- 关联文章
								local count = yield(function(gen)
									ArticleKeyword:select():where(ArticleKeyword.article.Eq(article))
												  :where(ArticleKeyword.keyword.Eq(keyword))
												  :count(gen)
								end)

								if 0 == count then
									--p(article)
									--p(keyword)
									local artkw = ArticleKeyword({
										article = article,
										keyword = keyword,
									})

									p(artkw)

									artkw:save(function(artkw)
										p(artkw)
									end)
								end


							end)
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

return function (req, res, handlers, app, gen)
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


	gen(true)
end
