local Index  = require('./base'):extend()

function Index:get()
   --[[ local this = self]]
    
	--self.db:connect(function(db)
		--db:execute('select * from cms_table;', function(err, res)
			--p(res)
			--this:finish()
		--end)
	--end)
	
	--self.app.task_queue.add({
		--time = 3,
		--count = 2,
		--callback = function()
			--p('ok')
		--end
	--[[})]]
	self:write(self.req.run_time)
	self:finish()
end

return Index
