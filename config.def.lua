local utils    = require('catke/utils')
local app_path = __dirname

local config = {
	app_path    = app_path,
	view_path   = app_path .. '/app/views/',
	sataic_path = app_path .. '/static/',
	debug       = true,
	port        = 8080,
	pqdb_lib    = '/usr/lib/libpq.5.dylib',
	database    = {}
}


return config
