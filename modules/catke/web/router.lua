--[[
简单路由
==========

## demo

```
#!lua

app = route(app, function(route)
    route('/post/:id', handler)
end)
```
]]

return function (app, setup)
    local routes = {}

    local router = function (path, handler)
        if path:match("/:") then
            local pattern = path:gsub("/(:[a-z]+)", "/([^/]+)")
            local names = {path:match("/:([a-z]+)")}
            path = function (path)
                local matches = {path:match(pattern)}
                if #matches == 0 or not matches[1] then return end
                local params = {}
                for i, name in ipairs(names) do
                    params[name] = matches[i]
            end
            return params
          end
        end
        routes[#routes + 1] = {path, handler}
    end

    setup(router)

    return function (req, res, application)
        for i, pair in ipairs(routes) do
            local path, handler = unpack(pair)
            if type(path) == "function" then
                local matches = path(req.url.path)
                if matches then
                    req.params = matches
                    return handler:new(req, res, application)
            end
            elseif req.url.path == path then
				req.params = req.params or {}
                return handler:new(req, res, application)
          end
        end
        app(req, res, application)
    end
end
