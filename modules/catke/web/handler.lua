local Object     = require('core').Object
local Validators = require('../utils').Validators
local String     = require('string')
local JSON       = require('json')
local Kernel     = require('./template')
local Handler    = Object:extend()

function Handler:initialize(req, res, application)
    self.req = req
    self.res = res
    self.app = application
	self.settings = application.settings

	--p(req)

	-- 默认的请求头
	self._headers = {}
	self._headers['Content-Type'] = "text/plain"

    self:init()

    self:execute()
end

-- handler 的初始化
function Handler:init()

end

function Handler:set_header(name, value)
	self._headers[name] = value
end

function Handler:set_default_headers()
end

function Handler:write_error(reason, code)
    if nil == code then
        code = "500"
    end

	self:set_header('Content-Length', #reason)

    self.res:writeHead(code, self._headers)
    self.res:write(reason)
    self.res:finish()
end

-- 输出
function Handler:write(x)
    res = self.res
	local body = x

	if Validators.is_string(x) then
		
		self:set_header('Content-Length', #body)
 		self:set_header('Content-Type', "text/html; charset=UTF-8")

        res:writeHead(200, self._headers)
        
    elseif Validators.is_table(x) then
        body = JSON.stringify(x)

		self:set_header('Content-Length', #body)
       	self:set_header('Content-Type', "application/json; charset=UTF-8")

		res:writeHead(200, self._headers)
	else
		body = tostring(body)
    end

    res:write(body)
    --self:finish()
end

-- 取模板目录
function Handler:get_template_path()
	return self.settings['view_path']
end

-- 渲染模板
function Handler:render(filename, data)
	local file_path = self:get_template_path() .. filename
	local handler   = self

	if self.settings['debug'] then
		Kernel.cache_lifetime = 0
	else
		Kernel.cache_lifetime = self.settings['tpl_cache']
	end

	Kernel._base_path = self:get_template_path()

	Kernel.compile(file_path, function(err, template)
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
        return self:delete()
    elseif 'patch' == method then
        return self:patch()
    elseif 'put' == method then
        return self:put()
    elseif 'options' == method then
        return self:options()
    end
end

return Handler
