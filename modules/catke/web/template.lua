local Kernel = require('kernel')
local Timer  = require('timer')
local UV     = require('uv')
local Table  = require('table')

Kernel._base_path = ''

function Kernel.helpers.Require(name, locals, callback)
    Kernel.compile(Kernel._base_path .. name, function (err, template)
        if err then return callback(err) end
        template(locals, callback)
    end)
end

function Kernel.helpers.If(condition, block, callback)
    if condition then block({}, callback)
    else callback(nil, "") end
end

function Kernel.helpers.Loop(array, block, callback)
    local left = 1
    local parts = {}
    local done
	--p(array)
    for i, value in ipairs(array) do
        left = left + 1
		if type(value) == 'table' then
        	value.index = i
		else
			local val = value
			value = {}
			value._ = val
		end

		--p(value)

        block(value, function (err, result)
            if done then return end
            if err then
                done = true
                callback(err)
                return
            end
            parts[i] = result
            left = left - 1
            if left == 0 then
                done = true
                callback(null, Table.concat(parts))
            end
        end)
    end
    left = left - 1
    if left == 0 and not done then
        done = true
        callback(null, Table.concat(parts))
    end
end

return Kernel
