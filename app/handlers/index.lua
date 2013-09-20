local Index  = require('./base'):extend()

function Index:get()
	local this = self
    
	self.db:connect(function(db)
		db:execute('select * from cms_table;', function(err, res)
			p(res)
			this:finish()
		end)
	end)

end

return Index
