local web     = require("catke/web")
local Handler = require("catke/web/handler")

local Index   = Handler:extend()

function Index:get()
	self:render('index.html', {
		test = 'v'
	})
end

web.static_path(__dirname .. "/static")

app = web.route('/', Index)

web.createServer(app, {
	view_path = __dirname .. '/app/views/'
}):listen(8080)

print("Server listening at http://localhost:8080/")
