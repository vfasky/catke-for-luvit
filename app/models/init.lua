local Postgres = require("catke/web/postgres")
local Mopee    = require('catke/web/mopee')

local config   = require("../../config")

Mopee.meta.database = Postgres:new(config['database'], config['pqdb_lib'])

local exports = {}

exports.Article = Mopee:new('article', {
	cid       = Mopee.IntegerField:new({index = true}),
	title     = Mopee.CharField:new({max_length = 255}),
	time      = Mopee.IntegerField:new({index = true}),
	summarize = Mopee.TextField:new({default = '[]'}),
	comment   = Mopee.TextField:new({default = '[]'}),
	content   = Mopee.TextField:new({null = true})
})


--p(exports.Article.comment)

exports.Keyword = Mopee:new('keyword', {
	title = Mopee.CharField:new({max_length = 255})
})

exports.ArticleKeyword = Mopee:new('article_keyword', {
	keyword = Mopee.ForeignKey:new(exports.Keyword),
	article = Mopee.ForeignKey:new(exports.Article),
	hasid   = Mopee.CharField:new({max_length = 30, unique = true})
})

return exports

