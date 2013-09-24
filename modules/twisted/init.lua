local coroutine = require('coroutine')
local table = require('table')

local exports = {}

local SENTINEL = {}
exports.SENTINEL = SENTINEL
exports.yield = coroutine.yield

local _unpack = function(...)
  -- this function is necessary because of the way lua
  --handles nil within tables and in unpack
  local args = {...}
  local coro_status = false
  local next_call = nil
  local extras = {}
  local extra_length = 0
  for k,v in pairs(args) do
    if k == 1 then
      coro_status = v
    elseif k == 2 then
      next_call = v
    else
      extras[k-2] = v
      extra_length = k - 2
    end
  end
  return coro_status, next_call, extras, extra_length
end

local __inline_callbacks
__inline_callbacks = function(coro, cb, ...)
  local v = ...
  local previous = nil
  local no_errs = true
  local extra_args = {}
  local length = 0
  while true do
    previous = v
    if coroutine.status(coro) == 'dead' then
      -- todo- pcall this and shove the result into the second argument or return an error or something
      if not cb then
        return
      end

      if type(previous) ~= 'table' then
        return cb(previous)
      else
        return cb(unpack(previous))
      end
    end
     -- yielded a function...
    if type(v) == 'function' then
       -- add a callback that will invoke coro
      local f = function(...)
        -- we resume ourselves later
        __inline_callbacks(coro, cb, ...)
      end
      -- replace the sentinel if it exists, with the function
      if extra_args[length] == SENTINEL then
        extra_args[length] = f
      else
        length = length + 1
        extra_args[length] = f
      end
      return v(unpack(extra_args, 1, length))
    end
    no_errs, v, extra_args, length = _unpack(coroutine.resume(coro, v))

    -- donegoofed?
    if no_errs ~= true then
      if cb then
        return cb(v)
      else
        return error(no_errs)
      end
    end

  end
end

exports.inline_callbacks = function(f)
  local coro = coroutine.create(f)
  return function(cb, ...)
    return __inline_callbacks(coro, cb, ...)
  end
end

return exports