
local Postgres = require("catke/web/postgres")
local Mopee    = require('catke/web/mopee')
local twisted  = require('twisted')
local yield    = twisted.yield
local config   = require("./config")

Mopee.meta.database = Postgres:new(config['database'], config['pqdb_lib'])


local TModel = Mopee:new('test_m', {
	test = Mopee.IntegerField:new({index = true}),
	title = Mopee.CharField:new({max_length = 100, default = 'ddddd'})
})
--[[
TModel:creat_table(function(ret)
	p(ret)
end)
]]

local model = TModel({
	test = 12
})

-- add
model:save(function(ar)
	p(ar)
	ar.test = 119
	-- edit
	ar:save(function(ar)
		p(ar)
	end)
end)


--Mopee.meta.database = Postgres:new(config['database'], config['pqdb_lib'])


--local Model = Mopee:new('test_model', {
	--test = Mopee.BooleanField(),
	--t2 = Mopee.IntegerField({index=true}),
	--title = Mopee.CharField({max_length = 255})
--})


--local model = Model({
	--test = true
--})


--model:save(function(sql)
	--p(sql)
--end)

