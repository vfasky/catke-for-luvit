local table  = require('table')
local Object = require('core').Object
local string = require('string')
local JSON   = require('json')

function string:split(sep)
	local sep, fields = sep or ":", {}
	local pattern = string.format("([^%s]+)", sep)
	self:gsub(pattern, function(c) fields[#fields+1] = c end)
	return fields
end

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

function Array:set(index, val)
	if index > self:length() then
		return false
	end
	self._data[index] = val
end

function Array:get(index, def)
	local value = def or nil

	if index > self:length() then
		return value
	end

	return self._data[index]

end


function Array:length()
    return table.getn(self._data)
end

function Array:join(sep)
    return table.concat(self._data, sep)
end

function Array:append(val)
    table.insert(self._data, val)
	return #self._data
end

function Array:each(callback)
	local k, v
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

function Array:sort(callback)
	table.sort(self._data, callback)
end

function Array:to_json()
	return JSON.stringify(self._data)
end

function Array.meta.__call(self)
	return self._data 
end

return {
    Array = Array
}
