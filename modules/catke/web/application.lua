local parse_url = require('http_parser').parseUrl
local http      = require("http")
local Response  = http.Response
local route     = require("./router")
local Array     = require("../base").Array
local utils     = require("../utils")
-- 主调度
local Application = {}

-- 404
function Response:not_found(reason)
    if nil == reason then
        reason = "file not found"
    end
    self:writeHead(404, {
        ["Content-Type"] = "text/plain",
        ["Content-Length"] = #reason
    })
    self:write(reason)
    self:finish()
end

-- 500
function Response:error(reason)
    if nil == reason then
        reason = "500"
    end
    self:writeHead(500, {
        ["Content-Type"] = "text/plain",
        ["Content-Length"] = #reason
    })
    self:write(reason)
    self:finish()
end

-- app的配置文件
Application.settings = {
	view_path = __dirname,
	debug     = true,
	tpl_cache = 3600 * 24 * 365
}

-- 中间件
Application._middlewares = Array:new()

-- 默认 404 处理
Application.handlers = function(req, res)
    res:not_found()
end

--添加路由及handler
Application.route = function(path, handler)
    return route(Application.handlers, function(route)
        route(path, handler)
    end)
end

--绑定中间件
Application.use = function(middleware)
    Application._middlewares:append(middleware)
	return Application
end

Application.createServer = function(handlers, settings)
	
	Application.settings = utils.extend(Application.settings, settings)

    return http.createServer(function (req, res)
        req.url = parse_url(req.url)

        -- 加载中间件
        Application._middlewares:each(function(middleware)
            handlers = middleware(req, res, handlers, Application)
			if false == handlers then
				return false
			end
        end)

		if handlers then
        	handlers(req, res, Application)
		end
    end)
end

return Application
