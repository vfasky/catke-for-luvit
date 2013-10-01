local Feed    = require('./base'):extend()
local models  = require('../models')
local Array   = require('catke/base').Array
local JSON    = require('json')
local os      = require('os')

local Article = models.Article

function Feed:get()
	local data = self.yield(function(gen)
		Article:select(Article.id, Article.title, Article.content, Article.date, Article.comment)
			   :order_by(Article.cid.Desc())
		       :page(1, 30)
			   :all(gen)
	end)

	local articles = Array:new()
	local date = os.time()

	data:each(function(ar, ix)
		if ix == 1 then
			data = ar.date
		end
		if ar.comment ~= '' then
			ar.comment = JSON.parse(ar.comment)
		else
			ar.comment = {}
		end
		ar.date = os.date('%Y-%m-%d %H:%M:%S', ar.date)

		ar.content = ar.content:sub(13, -15)

		articles:append(ar())
	end)

	--p(articles)

	self:render('feed.xml',{
		articles = articles(),
		date = os.date('%Y-%m-%d %H:%M:%S', date),
	})
end

return Feed
