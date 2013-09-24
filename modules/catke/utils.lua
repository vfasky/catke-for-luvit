local utils  = {}
local table  = require('table')
local Object = require('core').Object
local math   = require('math')

-- 验证
utils.Validators = {
    is_string = function (x)
        return 'string' == type(x) 
    end
    ,
    is_number = function (x)
        return 'number' == type(x) 
    end
    ,
    is_boolean = function (x)
        return 'boolean' == type(x) 
    end
    ,
    is_nil = function (x)
        return 'nil' == type(x) 
    end
    ,
    is_table = function (x)
        return 'table' == type(x) 
    end
}

-- 合并 table
utils.extend = function (base, data)
	base = utils.Validators.is_table(base) and base or {}
	data = utils.Validators.is_table(data) and data or {}

	for k, v in pairs(data) do
    	base[k] = v
  	end

	return base
end


local Promise = Object:extend()

function Promise:initialize(data_type, default)
	self._type   = data_type 
	self.default = default
end

function Promise.meta.__call(self, x)
	if x == nil then
		return self.default
	end

	if type(x) == self._type or self._type == "*" then
		return x
	elseif type(x) == "number" and self._type == "int" then
		if x == math.floor(x) then 
			return x
		end
	else
		return nil
	end
end

utils.Promise = Promise

return utils
