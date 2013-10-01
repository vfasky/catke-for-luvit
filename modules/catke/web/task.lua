--[[
任务队列
--]]
local Array = require('../base').Array
local utils = require('../utils')
local timer = require('timer')
local os    = require('os')
local math  = require('math')

local _tasks = Array:new()

local task_queue = {}
local task_id    = 0
local task_count = 0
local is_run     = false

-- 启动任务
local function run_task()
	timer.setInterval(1000, function()
		_tasks:each(function(task, ix)
			task_count = task_count + 1
			if task_count == 1000001 then
				task_count = 1
			end

			if task.count == 1 then
					
				if os.time() - task.creat_time >= task.time then
					task.callback()
					_tasks:remove(task)
				end
			else
				if task_count%task.time == 0 then
					task.callback()
					if task.count ~= -1 then
						task.count = task.count - 1
						if 0 >= task.count then
							_tasks:remove(task)
						end
					end
				end
			end
		end)
	end)
end

task_queue.add = function(task)
	task = utils.extend({
		creat_time = os.time(),
		time = 3600, -- 单位，秒
		count = 1, -- -1 为重复执行
		callback = function() end
	}, task)

	task_id = task_id + 1
	task.id = task_id 

	_tasks:append(task)

	return _tasks:index(task)
end

task_queue.remove = function(task_id)
	task = _tasks:get(task_id)
	_tasks:remove(task)
end

if false == is_run then
	is_run = true
	run_task()
end

return function (req, res, app, gen)
	app.task_queue = task_queue
	gen(true)
end
