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
	--todo: max_length
	if nil == value then
		value = self.attr.default 
	end
	self.value = value 
	return value
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
		fields.id = Mopee.IntegerField:new({pk = true, null = true})
		fields.id.order = 0
	end

	self._fields   = Array:new()
	self._db_table = db_table

	for name, field in pairs(fields) do
		field.name  = name
		field.model = self

		field(nil) -- 设置默认值
		self._fields:append(field)
		
		self[name] = field
	end

	self._fields:sort(function(a, b)
		return a.order < b.order
	end)


end

function Mopee:creat_table(callback)
	local stack  = Array:new()
	local indexs = Array:new()
	self._fields:each(function(field)
		stack:append(field:sql())
		if field.attr.index then
			indexs:append(field.name)
		end
	end)

	local sql = 'CREATE TABLE IF NOT EXISTS "%s" (%s);'
	sql = sql:format(self._db_table, stack:join(', '))

	local ix_sql = ''	
	-- creat index
	if indexs:length() > 0 then
		ix_sql = 'CREATE INDEX %s_idx ON "%s" (%s);'
		ix_sql = ix_sql:format(self._db_table, self._db_table, indexs:join(', '))
	end

	if self.meta.database then
		self.meta.database:connect(function(db)
			db:execute(sql, function(ret)
				--p(ix_sql)
				if '' == ix_sql then
					return callback(ret[0])
				end

				db:execute(ix_sql, callback)
			end)
		end)
		return
	end

	callback(sql .. ix_sql)
end

-- database
Mopee.meta.database = nil

local AR = Object:extend()

function AR:initialize(fields, model)
	self._fields = fields 
	self._model  = model

	fields:each(function(field)
		self[field.name] = field.value
	end)
end

function AR:save(callback)
	local is_insert = self.id == nil
	local values    = Array:new()
	local items     = Array:new()
	local seps      = Array:new()
	local stack     = Array:new()
	local sql       = ''
	self._fields:each(function(field)
		-- check
		local val = field(self[field.name])
		if nil == val and not field.attr.null then
			error(string.format('%s is Not null', field.name))
		end
		if nil ~= val and 'id' ~= field.name then
			values:append(val)
			items:append(string.format('"%s"', field.name))
			seps:append('%s')
			if false == is_insert then
				stack:append(string.format('"%s" = %s', field.name, '%s'))
			end
		end


	end)
	

	if is_insert then
		sql = string.format('INSERT INTO "%s" (%s) VALUES (%s) RETURNING id;',
			self._model._db_table, items:join(', '),  seps:join(', '))
	else
		sql = string.format('UPDATE "%s" SET %s WHERE "id"=%s;',
			self._model._db_table, stack:join(', '), self.id)

	end

	local database = self._model.meta.database 
	if nil == database then
		callback(sql, values)
		return
	end
	
	local this = self
	values:append(function(ret)
		if is_insert and ret[1] and ret[1][1] then
			this.id = tonumber(ret[1][1])
		end
		callback(this)
	end)

	database:connect(function(db)
		db:execute(sql, unpack(values()))
	end)
end

function AR:delete(callback)

end

function Mopee.meta.__call(self, args)
	local tasks = Array:new()
	local this  = self
	args = args or {}
	for k, v in pairs(args) do
		self._fields:each(function(field)
			if field.name == k then
				field(v)
			end
		end)
	end

	return AR:new(self._fields, self)
end



return Mopee
