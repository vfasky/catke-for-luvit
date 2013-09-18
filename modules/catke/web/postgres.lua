local Object = require('core').Object
local utils  = require('../utils')

local postgresLuvit 
local _connect = nil

local Postgres = Object:extend()

function Postgres:initialize(setting, lib_path)
	setting = utils.extend({
		dbname = 'test',
		host = '127.0.0.1',
		port = '5432',
		user = '',
		password = ''
	}, (setting or {}))

	_G.POSTGRESQL_LIBRARY_PATH = lib_path or '/usr/lib/libpq.5.dylib'
	postgresLuvit = require('luvit-postgres/postgresLuvit')

	self._dsn = 'dbname=' .. setting['dbname'] .. ' host=' .. setting['host'] .. ' port=' .. setting['port'] 

	
	if setting['user'] ~= '' then
		self._dsn = self._dsn .. ' user=' .. setting['user'] 
	end

	if setting['password'] ~= '' then
		self._dsn = self._dsn .. ' password=' .. setting['password'] 
	end

end


function Postgres:connect(callback)
	if nil == _connect then
		_connect = postgresLuvit:new(self._dsn, function(err)
			callback(nil, self)
		end)

		return
	end

	callback(nil, self)
end


function Postgres:execute(sql, callback)
	if _connect then
		_connect:sendQuery(sql, callback)
		return
	end

	Postgres:connect(function(err, con)
		_connect:sendQuery(sql, callback)
	end)
end

return Postgres
