local table = require 'table'

-- class.lua
-- Compatible with Lua 5.1 (not 5.0).
local Class = function (base, init)
    local c = {}     -- a new class instance
    if not init and type(base) == 'function' then
        init = base
        base = nil
    elseif type(base) == 'table' then
     -- our new class is a shallow copy of the base class!
        for i,v in pairs(base) do
            c[i] = v
        end
        c._base = base
    end
    -- the class will be the metatable for all its objects,
    -- and they will look up their methods in it.
    c.__index = c

    -- expose a constructor which can be called by <classname>(<args>)
    local mt = {}
    mt.__call = function(class_tbl, ...)
    local obj = {}
    setmetatable(obj,c)
    if init then
        init(obj,...)
    else 
        -- make sure that any stuff from the base class is initialized!
        if base and base.init then
            base.init(obj, ...)
        end
    end
    return obj
    end
    c.init = init
    c.is_a = function(self, klass)
        local m = getmetatable(self)
        while m do 
            if m == klass then return true end
            m = m._base
        end
        return false
    end
    setmetatable(c, mt)
    return c
end

--[[
数组的实现
==========
]]
local Array = Class()

function Array:init()
    self._data = {}
end

function Array:length()
    return table.getn(self._data)
end

function Array:join(sep)
    return table.concat(self._data, sep)
end

function Array:append(val)
    table.insert(self._data, val)
end

function Array:each(callback)
    for k, v in ipairs(self._data) do
        if false == callback(v, k) then
            break
        end
    end
end

function Array:index(val)
    index = -1
    self:each(function(v, k)
        if v == val then
            index = k
            return false
        end
    end)
    return index
end

function Array:remove(val)
    index = self:index(val)
    if not (index == -1) then
        table.remove(self._data, index)
    end
end

return {
    Class = Class ,
    Array = Class(Array)
}