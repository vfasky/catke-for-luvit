
local Postgres = require("catke/web/postgres")
local Mopee    = require('catke/web/mopee')
local twisted  = require('twisted')
local yield    = twisted.yield
local config   = require("./config")

local TModel = Mopee:new('test_m', {
	test = Mopee.IntegerField:new({index = true}),
	title = Mopee.CharField:new({max_length = 100, default = 'ddddd'})
})

--p(TModel)

local model = TModel({
	test = 'test',
})

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

