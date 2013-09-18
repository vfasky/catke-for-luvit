local Handler  = require("catke/web/handler")
local Base = Handler:extend()

-- handler 的初始化
function Base:init()
	self.db = self.application.database
end

return Base
