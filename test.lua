
local Postgres = require("catke/web/postgres")
local Mopee    = require('catke/web/mopee')
local twisted  = require('twisted')
local yield    = twisted.yield
local config   = require("./config")

--Mopee.meta.database = Postgres:new(config['database'], config['pqdb_lib'])


local TModel = Mopee:new('test_m', {
	test = Mopee.IntegerField:new({index = true}),
	title = Mopee.CharField:new({max_length = 100, default = 'ddddd'})
})

local T2Model = Mopee:new('test2_m', {
	tmodel = Mopee.ForeignKey:new(TModel)
})

local model = TModel({
	test = 12,
	id = 1
})

local model2 = T2Model({
	tmodel = model
})

T2Model:select():all()

T2Model:select(T2Model.id, T2Model.tmodel, TModel.title)
       :join(TModel.id.Eq(1))
	   :where(TModel.title.In({1,5,6}))
	   :or_where(TModel.id.Ge(3))
	   :order_by(TModel.id.Asc())
       :get()

--[[
model2:save(function(ret, id)
	p(ret, id)
end)

--[[
T2Model:creat_table(function(ret)
	p(ret)
end)

TModel:creat_table(function(ret)
	p(ret)
end)

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
		
		ar:delete(function(ret)
			p(ret)
		end)
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
]]
