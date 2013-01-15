local parse_url = require('http_parser').parseUrl
local http      = require("http")
local Response  = http.Response
local route     = require("./router")
local Array     = require("../base").Array

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

-- 主调度
local Application = {}

-- 中间件
Application._middlewares = Array()
--Application._middlewares:append( require('./cleanup') )

-- 默认 404 处理
Application.handlers = function(req, res)
    res:not_found()
end

-- 设置静态目录
Application.static_path = function(path)
    Application.handlers = require('./static')(Application.handlers, path)
end

--添加路由及handler
Application.route = function(path, handler)
    return route(Application.handlers, function(route)
        route(path, handler)
    end)
end

Application.use = function(middleware)
    Application._middlewares:append(middleware)
end

Application.createServer = function(app)
    local application = self
    return http.createServer(function (req, res)
        req.url = parse_url(req.url)

        -- 加载中间件
        Application._middlewares:each(function(middleware)
            app = middleware(app)
        end)

        app(req, res, application)
    end)
end

return Application