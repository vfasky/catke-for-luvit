--[[
自动连接数据库
--]]
local Postgres = require("catke/web/postgres")

local _postgres

return function(req, res, handlers, app, callback)
	
	if not _postgres then
		_postgres = Postgres:new(app.settings['database'], app.settings['pqdb_lib'])
	end

	app.database = _postgres

	return handlers
end



