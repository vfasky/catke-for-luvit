local Index   = require('./base'):extend()
local Article = require('../models').Article
local Array   = require('catke/base').Array
local JSON    = require('json')
function Index:get()
    local this = self

	local page = tonumber(self.req.params.page) or 1
	
	if page > 1000 or page < 1 then
		page = 1
	end
    

	local data = self.yield(function(gen)
		Article:select(Article.id, Article.title, Article.summarize)
			   :order_by(Article.cid.Desc())
		       :page(page, 10)
			   :all(gen)
	end)

	local articles = Array:new()

	data:each(function(ar)
		if ar.summarize ~= '' then
			ar.summarize = JSON.parse(ar.summarize)
		else
			ar.summarize = {}
		end
		--p(ar())
		articles:append(ar())
	end)

	--p(articles())
	
	self:render('index.html', {
		page = page,
		title = '最新资讯',
		keywords = 'cnbeta, 全文RSS, 全文Feed, cnbeta 热门评论',
		description = '精心炮制的cnbeta 全文RSS, 附上吊丝级评论；还你干净优雅的阅读环境。',
		articles = articles(),
	})
end

return Index
