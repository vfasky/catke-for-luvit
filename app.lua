local web      = require("catke/web")
local config   = require("./config")

local app = web.route('/', require('./app/handlers/index'))

-- 加载静态目录中间件
web.use(require('catke/web/static')(config['sataic_path']))
web.use(require('catke/web/task')) -- 使用任务队列
web.use(require('./app/middlewares/init-app')) 

web.createServer(app, config):listen(config['port'])

print("Server listening at http://localhost:" .. config['port'] .. "/")
