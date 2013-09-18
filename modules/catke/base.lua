local table  = require 'table'
local Object = require('core').Object

--[[
数组的实现
==========
]]
local Array = Object:extend()

function Array:initialize(data)
    self._data = data or {}
end

function Array:clear()
	self._data = {}
end

function Array:get(index)
	local value = nil

	if index > Array:length() then
		return value
	end

	Array:each(function(v, k)
		if k == index then
			value = v
			return false
		end
	end)

	return value
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
    Array = Array
}
