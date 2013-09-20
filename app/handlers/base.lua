local Handler  = require("catke/web/handler")
local Base = Handler:extend()

-- handler 的初始化
function Base:init()
	self.db = self.app.database
end

return Base
