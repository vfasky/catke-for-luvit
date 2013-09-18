local Index  = require('./base'):extend()

function Index:get()
	--[[
	local this = self
    self.db:connect(function(err, db)
		db:execute('select * from cms_table;', function(err, res)
			p(res)
			this:finish()
		end)
	end)
	
	self:write({test='ok'})
	]]
	
	self:render('index.html', {
		test = 'v'
	})
end

return Index
