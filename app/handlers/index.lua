local Index  = require('./base'):extend()

function Index:get()
    local this = self
    
	local test = self.yield(function(gen)
		gen('ok')
	end)
	
	self:write(test)
	self:finish()
end

return Index
