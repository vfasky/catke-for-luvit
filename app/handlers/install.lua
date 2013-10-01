local Install  = require('./base'):extend()
local models   = require('../models')

local Article        = models.Article
local Keyword        = models.Keyword
local ArticleKeyword = models.ArticleKeyword

function Install:get()
    local this = self
    
	-- article
	self.yield(function(gen)
		Article:creat_table(gen)
	end)

	-- keyword
	self.yield(function(gen)
		Keyword:creat_table(gen)
	end)

	-- article keyword
	self.yield(function(gen)
		ArticleKeyword:creat_table(gen)
	end)
	
	self:write('install success')
	self:finish()
end

return Install
