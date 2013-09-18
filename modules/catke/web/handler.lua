local Class      = require('../base').Class
local Validators = require('../utils').Validators
local String     = require('string')
local Handler    = Class()
local JSON       = require('json')
local Kernel     = require('./template')

function Handler:init(req, res, application)
    self.req = req
    self.res = res
    self.application = application
	self.settings    = application.settings

    self:initialize()

    self:execute()
end

-- handler 的初始化
function Handler:initialize()

end

function Handler:write_error(reason, code)
    if nil == code then
        code = "500"
    end

    self.res:writeHead(code, {
        ["Content-Type"] = "text/plain",
        ["Content-Length"] = #reason
    })
    self.res:write(reason)
    self.res:finish()
end

-- 输出
function Handler:write(x)
    res = self.res
    local body = tostring(x)

    if Validators.is_string(x) then
        body = x
        res:writeHead(200, {
            ["Content-Type"] = "text/html; charset=UTF-8",
            ["Content-Length"] = #body
        })
        
    elseif Validators.is_table(x) then
        body = JSON.stringify(x)
        res:writeHead(200, {
            ["Content-Type"] = "application/json; charset=UTF-8",
            ["Content-Length"] = #body
        })
    end
    res:write(body)
    --self:finish()
end

-- 渲染模板
function Handler:render(filename, data)
	local file_path = self.settings['view_path'] .. filename
	local handler   = self

	if self.settings['debug'] then
		Kernel.cache_lifetime = 0
	end

	Kernel._base_path = self.settings['view_path']

	Kernel.compile(file_path, function (err, template)
		if err then
			handler:write_error(err)
			return
		end

		template(data, function(err, result)
			if err then
				handler:write_error(err)
				return
			end
			handler:write(result)
			handler:finish()

		end)
	end)

end

-- 结束请求前执行
function Handler:on_finish()

end

-- 向浏览器发送"结束"
function Handler:finish()
    self:on_finish()
    return self.res:finish()
end

function Handler:head()
    self:write_error('Method not allowed', 405)
end

function Handler:get()
    self:write_error('Method not allowed', 405)
end

function Handler:post()
    self:write_error('Method not allowed', 405)
end

function Handler:delete()
    self:write_error('Method not allowed', 405)
end

function Handler:patch()
    self:write_error('Method not allowed', 405)
end

function Handler:put()
    self:write_error('Method not allowed', 405)
end

function Handler:options()
    self:write_error('Method not allowed', 405)
end

function Handler:execute()
    local method = String.lower(self.req.method)
    if 'get' == method then
        return self:get()
    elseif 'post' == method then
        return self:post()
    elseif 'head' == method then
        return self:head()
    elseif 'delete' == method then
        return self:post()
    elseif 'patch' == method then
        return self:post()
    elseif 'put' == method then
        return self:post()
    elseif 'options' == method then
        return self:post()
    end
end

function Handler:extend()
    return Class(Handler)
end

return Handler
