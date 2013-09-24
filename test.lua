
local Postgres = require("catke/web/postgres")
local Mopee    = require('catke/web/mopee')
local twisted  = require('twisted')
local yield    = twisted.yield
local config   = require("./config")

Mopee.meta.database = Postgres:new(config['database'], config['pqdb_lib'])


local Model = Mopee:new('model', {
	test = Mopee.BooleanField(),
	title = Mopee.CharField({max_length = 255})
})

local model = Model({
	test = true
})


--model:save(function(sql)
	--p(sql)
--end)

Model:create_table(function(sql)
	p(sql)
end)

--local sync = twisted.inline_callbacks(function()
	--local res = yield(function(cb)
		--model:create_table(function(sql)
			--cb(sql)
		--end)
	--end)
	
	--return {nil, res}
--end)

--sync(function(err, res)
  --if err then
    --return p('there was an err', err)
  --end
  --p('the result is: ', res)
--[[end)]]


