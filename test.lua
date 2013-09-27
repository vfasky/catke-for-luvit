
local Postgres = require("catke/web/postgres")
local Mopee    = require('catke/web/mopee')
local twisted  = require('twisted')
local yield    = twisted.yield
local config   = require("./config")

Mopee.meta.database = Postgres:new(config['database'], config['pqdb_lib'])


local Article = Mopee:new('article', {
	cid       = Mopee.IntegerField:new({index = true}),
	title     = Mopee.CharField:new({max_length = 255}),
	summarize = Mopee.TextField:new({default = '[]'}),
	comment   = Mopee.TextField:new({default = '[]'}),
	content   = Mopee.TextField:new({null = true})
})

local Keyword = Mopee:new('keyword', {
	title = Mopee.CharField:new({max_length = 255})
})

local ArticleKeyword = Mopee:new('article_keyword', {
	keyword = Mopee.ForeignKey:new(Keyword),
	article = Mopee.ForeignKey:new(Article),
})

Article:select():where(Article.cid.Eq(1))
       :get(function(ar)
		   ar.title = 'change title'
		   ar:save(function(ar)
			   p(ar)
		   end)
		end)


--local article = Article({
	--cid = 1,
	--title = 'test',
	--content = 'content'
--})

--article:save(function(ar)
	--p(ar)
--end)



--Article:creat_table(function(ret)
	--Keyword:creat_table(function(ret)
		--ArticleKeyword:creat_table(function(ret)
			--p(ret)
		--end)
	--end)
--end)

