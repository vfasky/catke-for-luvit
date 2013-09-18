local utils = {}
local table = require('table')

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
	return setmetatable(data, {__index=base})
end

return utils
