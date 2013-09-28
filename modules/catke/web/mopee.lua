local table   = require('table')
local Object  = require('core').Object
local string  = require('string')
local Array   = require('../base').Array
local utils   = require('../utils')

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
	if nil == x and self.default then
		return self.default
	end
	return x
end

function Field:unserialize(x)
	return x
end

-- 设置值
function Field.meta.__call(self, x)
	local value = self.data_type(self:serialize(x))
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
	self.order_by  = 'DESC'
	self.promise   = self:defautl_promise()
	self.attr      = {}
	self.data_type = utils.Promise:new('number')

	self.name  = nil
	self.model = nil
	self.value = nil

	_field_ix  = _field_ix + 1
	self.order = _field_ix

	--p(args)
	for k, v in pairs(self.promise) do
		if args and args[k] then
			self.attr[k] = v(args[k])
		else
			self.attr[k] = v.default
		end
	end

	self._format_val = function(x)
		return x
	end

	
	self.As = function(name)
		local this = utils.copy(self)
		this._as_name = name
		return this
	end

	self.get_name = function()
		return self._as_name or self.name
	end

	self.sql_name = function()
		return string.format('"%s"."%s" AS "%s"', 
			self.model._db_table, self.name, self.get_name())
	end

	self.Asc = function()
		return string.format('"%s" ASC', self.get_name())
	end

	self.Desc = function()
		return string.format('"%s" DESC', self.get_name())
	end
	
	-- 小于
	self.Lt = function(x)
		x = self._format_val(x)
		return { 
			this = self,
			name = self.get_name(),
			type = '<',
			value = x
		}
	end
	
	-- 小于等于
	self.Le = function(x)
		x = self._format_val(x)

		return { 
			this = self,
			name = self.get_name(),
			type = '<=',
			value = x
		}
	end
	
	-- 大于
	self.Gt = function(x)
		x = self._format_val(x)

		return { 
			this = self,
			name = self.get_name(),
			type = '>',
			value = x
		}
	end

	
	-- 大于等于
	self.Ge = function(x)
		x = self._format_val(x)

		return { 
			this = self,
			name = self.get_name(),
			type = '>=',
			value = x
		}
	end

	-- 不等于
	self.Ne = function(x)
		x = self._format_val(x)

		return { 
			this = self,
			name = self.get_name(),
			type = '!=',
			value = x
		}
	end
	
	-- 等于
	self.Eq = function(x)
		x = self._format_val(x)

		if x == nil then
			x = ''
		end

		return { 
			this = self,
			name = self.get_name(),
			type = '=',
			value = x
		}
	end

	self.Link = function(x)
		x = self._format_val(x)

		if x == nil then
			x = ''
		end

		return { 
			this = self,
			name = self.get_name(),
			type = 'LINK',
			value = x
		}
	end

	self.Ilink = function(x)
		x = self._format_val(x)

		if x == nil then
			x = ''
		end

		return { 
			this = self,
			name = self.get_name(),
			type = 'ILINK',
			value = x
		}
	end


	-- Not In 查询
	self.NotIn = function(list)
		local values  = Array:new()
		local promise = utils.Promise:new('number', 0)

		list = list or {}

		if type(list) ~= 'table' then
			return false
		end

		for k, v in ipairs(list) do
			v = self._format_val(v)

			local value = promise(v)

			if 0 ~= value then
				values:append(value)
			end
		end

		if 0 == values:length() then
			return false
		end

		return { 
			this = self,
			name = self.get_name(),
			type = 'NOT IN',
			value = string.format('(%s)', values:join(', '))
		}
	end

	
	-- In 查询
	self.In = function(list)
		local values  = Array:new()
		local promise = utils.Promise:new('number', 0)

		list = list or {}

		if type(list) ~= 'table' then
			return false
		end

		for k, v in ipairs(list) do
			v = self._format_val(v)

			local value = promise(v)

			if 0 ~= value then
				values:append(value)
			end
		end

		if 0 == values:length() then
			return false
		end
			
		return { 
			this = self,
			name = self.get_name(),
			type = 'IN',
			value = string.format('(%s)', values:join(', '))
		}
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

function IntegerField:serialize(x)
	if nil ~= x then
		return tonumber(x)
	end
	return x
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

local TextField = Field:extend()
Mopee.TextField = TextField 

function TextField:initialize(...)
	--p(...)

	self:init(...)
	self.data_type = utils.Promise:new('string')
end


function TextField:sql()
	local sql = '"%s" TEXT'
	
	return sql:format(self.name)
end

local ForeignKey = Field:extend()
Mopee.ForeignKey = ForeignKey 

function ForeignKey:initialize(target)
	self:init()
	self.target = target
	self.data_type = utils.Promise:new('number')

	self._format_val = function(x)
		if type(x) == 'table' then
			return x.id
		end
		return x
	end

end


function ForeignKey:sql()
	local sql = '"%s" INT REFERENCES "%s" ("%s") ON UPDATE NO ACTION ON DELETE NO ACTION'
	return sql:format(self.name, self.target._db_table, self.target.id.name)
end

function ForeignKey:serialize(x)
	if type(x) == 'table' then
		return x.id
	end
	return x
end

--function ForeignKey:unserialize(x)
	--return x
--end



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

function AR:initialize(model)
	self._model  = model
	self._fields = model._fields 

	self._fields:each(function(field)
		--p(field.name, field.value)
		self[field.name] = field:unserialize(field.value)
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
			--p(self)
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
		sql = string.format('INSERT INTO "%s" (%s) VALUES (%s) RETURNING "id";',
			self._model._db_table, items:join(', '),  seps:join(', '))
	else
		sql = string.format('UPDATE "%s" SET %s WHERE "id"=%s;',
			self._model._db_table, stack:join(', '), self.id)

	end

	if nil == callback then
		return
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
	local database = self._model.meta.database 
	local this     = self
	if self.id then
		local sql = string.format('DELETE FROM "%s" WHERE "id"=%s;',
			self._model._db_table, '%s')
		
		if nil == database then
			callback(sql)
			return
		end

		database:connect(function(db)
			db:execute(sql, this.id, function(ret)
				this = nil
				callback(true)
			end)
		end)
	end
end

local Query = Object:extend() 

function Query:initialize(model, ...)
	self._select   = Array:new()
	self._model    = model
	self._where    = Array:new()
	self._or       = Array:new()
	self._join     = Array:new()
	self._order_by = Array:new()
	self._limit    = nil
	self._offset   = nil
	self.database = Mopee.meta.database

	local args = { ... }
	for k, v in ipairs(args) do
		self._select:append(v.sql_name())
	end

end

function Query:where(...)
	local args = { ... }
	for k, v in ipairs(args) do
		self._where:append(v)
	end
	return self
end

function Query:or_where(...)
	local args = { ... }
	for k, v in ipairs(args) do
		self._or:append(v)
	end
	return self
end

function Query:order_by(...)
	local args = { ... }
	for k, v in ipairs(args) do
		self._order_by:append(v)
	end
	return self

end

function Query:join(...)
	local args = { ... }
	for k, v in ipairs(args) do
		self._join:append(v)
	end
	return self
end

function Query:count(callback)
	local compiler   = self:compiler_sql()
	local sql        = string.format("SELECT COUNT(*) FROM %s %s", 
		compiler.table_sql,
		compiler.where_sql
	)

	compiler.values:append(function(ret)
		--p(ret[1][1])
		callback(tonumber(ret[1][1]))
	end)
	
	self._model.meta.database:connect(function(db)
		db:execute(sql, unpack(compiler.values()))
	end)

end

function Query:get(callback)
	self._offset = 0
	self._limit  = 1

	callback = callback or function() end

	self:all(function(data)
		if data:length() == 0 then
			callback(nil)
			return
		end

		callback(data:get(1))
	end)
end

function Query:compiler_sql()
		-- 需要转义的值
	local values     = Array:new()

	local select_sql = '*'

	if self._select:length() > 0 then
		select_sql = self._select:join(', ')
	end

	local table_sql = string.format('"%s"', self._model._db_table)

	if self._join:length() > 0 then
		local tables = Array:new()
		tables:append(string.format('"%s"', self._model._db_table))

		self._join:each(function(field)
			local db_table = string.format('"%s"', field.this.model._db_table)
			if tables:index(db_table) == -1 then
				tables:append(db_table)
			end

			self._where:append(field)
		end)

		table_sql = tables:join(', ')
	end

	local where_sql = ''
	-- where
	
	if self._where:length() > 0 then

		local wheres = Array:new()

		self._where:each(function(where)
			if where then
				if where.type ~= 'IN' and where.type ~= 'NOT IN' then
					values:append(where.value)
	
					wheres:append(string.format('"%s" %s %s', where.name, where.type, '%s'))
				else
					wheres:append(string.format('"%s" %s %s', where.name, where.type, where.value))
				end
			end
		end)

		where_sql = string.format(' WHERE ( %s )', wheres:join(' AND '))

	end

	-- or where

	if self._or:length() > 0 then
		if self._where:length() > 0 then
			where_sql = where_sql .. ' OR '
		else
			where_sql = ' WHERE '
		end

		local ors = Array:new()

		self._or:each(function(where)
			if where then
				if where.type ~= 'IN' and where.type ~= 'NOT IN' then
					values:append(where.values)
					ors:append(string.format('"%s" %s %s', where.name, where.type, '%s'))
				else
					ors:append(string.format('"%s" %s %s', where.name, where.type, where.value))
				end
			end
		end)

		where_sql = string.format('%s ( %s )', where_sql, ors:join(' OR '))
	end

	
	return {
		select_sql = select_sql,
		table_sql = table_sql,
		where_sql = where_sql,
		values = values
	}

end

function Query:all(callback)
	callback = callback or function() end
	local compiler   = self:compiler_sql()
	local sql        = string.format("SELECT %s FROM %s %s", 
		compiler.select_sql, 
		compiler.table_sql,
		compiler.where_sql
	)

	if self._limit then
		sql = sql .. ' LIMIT ' .. tonumber(self._limit)
	end

	if self._offset then
		sql = sql .. ' OFFSET ' .. tonumber(self._offset)
	end

	if self._order_by:length() > 0 then
		sql = sql .. ' ORDER BY ' .. self._order_by:join(', ')
	end
	
	
	compiler.values:append(function(ret)
		local data = Array:new()

		ret:each(function(val)
			data:append(self._model(val))
		end)

		callback(data)
	end)

	self._model.meta.database:connect(function(db)
		db:query(sql, unpack(compiler.values()))
	end)
	
end



function Mopee:select(...)
	return Query:new(self, ...)
end

function Mopee:execute(sql, ...)
	if nil == Mopee.meta.database then
		return
	end
	local args = { ... }
	Mopee.meta.database:connect(function(db)
		db:execute(sql, unpack(args))
	end)
end

function Mopee.meta.__call(self, args)
	local tasks = Array:new()
	local this  = self
	args = args or {}

	-- set field value
	for k, v in pairs(args) do
		this._fields:each(function(field)
			if field.name == k then
				field(v)	
			end
		end)
	end

	return AR:new(this)
end



return Mopee
