local Emitter  = require('core').Emitter
local web      = require("catke/web")
local config   = require("./config")

-- 错误处理
function Emitter:missingHandlerType(name, ...)
	if name == 'error' then
		p('=========== error ==========')
		p(...)
		p('=========== end ==========')
	end
end

-- 加载静态目录中间件
web.use(require('catke/web/static')(config['sataic_path']))
web.use(require('catke/web/task')) -- 使用任务队列
web.use(require('./app/middlewares/init-app')) 


web.route('/', require('./app/handlers/index'))
web.route('/feed', require('./app/handlers/feed'))
web.route('/page/:page', require('./app/handlers/index'))
web.route('/view/:id', require('./app/handlers/view'))
web.route('/install', require('./app/handlers/install'))


web.createServer(config):listen(config['port'])

print("Server listening at http://localhost:" .. config['port'] .. "/")
