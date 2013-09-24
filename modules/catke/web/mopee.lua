local table   = require('table')
local Object  = require('core').Object
local string  = require('string')
local math    = require('math')
local twisted = require('twisted')
local Array   = require('../base').Array
local utils   = require('../utils')
local yield   = twisted.yield

local Mopee = Object:extend()


-- 用于字段排序
local _field_ix = 0

local Field = Object:extend()
Mopee.Field = Field

function Field:defautl_promise()
	return {
		pk      = utils.Promise:new('boolean', false),
		index   = utils.Promise:new('boolean', false),
		null    = utils.Promise:new('boolean', false),
		default = utils.Promise:new('*'),
		unique  = utils.Promise:new('boolean', false),
		max_length = utils.Promise:new('number', 0)
	}
end

function Field:serialize(x)
	return x
end

function Field:unserialize(x)
	return x
end

-- 设置值
function Field.meta.__call(self, x)
	local value = self:serialize(self.data_type(x))
	if nil == value then
		value = self.attr.default 
	end
	self.value = value 
end

function Field:initialize(args)
	self:init(args)
end

function Field:init(args)

	self.promise   = self:defautl_promise()
	self.attr      = {}
	self.data_type = utils.Promise:new('number')

	self.name  = nil
	self.model = nil
	self.value = nil

	_field_ix  = _field_ix + 1
	self.order = _field_ix

	for k, v in pairs(self.promise) do
		if args and args[k] then
			self.attr[k] = v(args[k])
		else
			self.attr[k] = v.default
		end
	end

end

-- int 类型
local IntegerField = Field:extend()
Mopee.IntegerField = IntegerField 

function IntegerField:sql()
	local sql = '"%s" INTEGER'

	if self.attr.pk then
		sql =  '"%s" SERIAL PRIMARY KEY'
		
	else
		if self.attr.unique then
			sql = sql .. " UNIQUE"
		end
		if not self.attr.null then
			sql = sql .. " NOT NULL"
		end
		if self.default then
			sql = sql .. ' DEFAULT "' .. tostring(self.default) .. '"'
		end
	end
	return sql:format(self.name)

end

-- char 类型
local CharField = Field:extend()
Mopee.CharField = CharField 

function CharField:initialize(...)
	self:init(...)

	self.data_type = utils.Promise:new('string')
end

function CharField:sql()
	local sql =  '"%s" VARCHAR(%s)'
	sql = sql:format(self.name, self.attr.max_length)
	
	if self.attr.unique then
		sql = sql .. " UNIQUE"
	end
	if not self.attr.null then
		sql = sql .. " NOT NULL"
	end
	if self.default then
		sql = sql .. ' DEFAULT "%s"'
		sql = sql:format(self.default)
	end
	return sql

end


function Mopee:initialize(db_table, fields)
	if not fields.id then 
		fields.id = Mopee.IntegerField:new({pk = true})
		fields.id.order = 0
	end

	self.fields = Array:new()

	for name, field in pairs(fields) do
		field.name  = name
		field.model = self

		field(nil) -- 设置默认值
		self.fields:append(field)
	end

	self.fields:sort(function(a, b)
		return a.order < b.order
	end)

	self.fields:each(function(field)
		--p(field:sql())
	end)

end

function Mopee.meta.__call(self, args)
	local tasks = Array:new()
	local this  = self
	for k, v in pairs(args) do
		self.fields:each(function(field)
			if field.name == k then
				field(v)
			end
		end)
	end

	local count   = tasks:length()
	local success = 0

	p(this.fields())
end

return Mopee
