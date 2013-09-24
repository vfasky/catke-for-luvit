local Kernel = require('./kernel')
local Timer = require('timer')
local UV = require('uv')
local Table = require('table')
Kernel.cache_lifetime = 0 -- disable cache

function Kernel.helpers.PARTIAL(name, locals, callback)
  Kernel.compile(name, function (err, template)
    if err then return callback(err) end
    template(locals, callback)
  end)
end

function Kernel.helpers.IF(condition, block, callback)
  if condition then block({}, callback)
  else callback(nil, "") end
end

function Kernel.helpers.LOOP(array, block, callback)
  local left = 1
  local parts = {}
  local done
  for i, value in ipairs(array) do
    left = left + 1
    value.index = i
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

local site = {
  name = "Tim Caswell"
}

Kernel.compile("tasks.html", function (err, template)
  if err then p("error",err); return end
  local data = {
    tasks = {
      {task = "Program Awesome Code"},
      {task = "Play with Kids"},
      {task = "Answer Emails"},
      {task = "Write Blog Post"},
    }
  }
  setmetatable(data, {__index=site})
  template(data, function (err, result)
    if err then p("ERROR", err); return end
    p("result")
    print(result)
  end)
end)


