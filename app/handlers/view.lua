local View   = require('./base'):extend()
local models = require('../models')
local JSON   = require('json')
local date     = require('os').date
local Array  = require('catke/base').Array

function View:get()
	local this = self

	local id = tonumber(self.req.params.id) 

	if not id then
		self:write_error(404)
		return
	end

	local article = self.yield(function(gen)
		models.Article:select():where(models.Article.id.Eq(id))
		                       :get(gen)
	end)

	local pre_article = self.yield(function(gen)
		models.Article:select(models.Article.id, models.Article.title)
					  :where(models.Article.id.Gt(id))
					  :order_by(models.Article.cid.Asc())
					  :get(gen)
	end)

	local next_article = self.yield(function(gen)
		models.Article:select(models.Article.id, models.Article.title)
					  :where(models.Article.id.Lt(id))
					  :order_by(models.Article.cid.Desc())
					  :get(gen)
	end)

	if nil == article then
		self:write_error(404)
		return
	end

	if '' ~= article.summarize then
		article.summarize = JSON.parse(article.summarize)
	end

	if '' ~= article.comment then
		article.comment = JSON.parse(article.comment)
	end

	local description_arr = Array:new()

	for _, v in ipairs(article.summarize) do
		description_arr:append(v:gsub('"', ''))
	end

	article.date = date('%Y-%m-%d %H:%M:%S', article.date)
	--p(article.date)

	-- 取关键字
	local keywords = self.yield(function(gen)
		models.Keyword:select(models.ArticleKeyword.id, models.Keyword.title)
					  :join(models.ArticleKeyword.article.Eq(article))
					  :order_by(models.ArticleKeyword.id.Asc())
					  :all(gen)
	end)

	local keyword_arr = Array:new()

	keywords:each(function(v)
		keyword_arr:append(v.title)
	end)

	-- 处理标题
	local title_arr = article.title:split('%_')
	if #title_arr == 2 then
		article.title = title_arr[1]
	end

	article.content = article.content:sub(13, -15)
	--p(article)
	
	--p(pre_article)
	--p(next_article)
	
	self:render('view.html',{
		title = article.title,
		article = article,
		description = description_arr:join(';'),
		pre_article = pre_article,
		next_article = next_article,
		keywords = keyword_arr:join(',')
	})


end



return View
