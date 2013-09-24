-- types
-- - static
-- - variable
-- - function (always async, can pass in args)
-- - block always async, can have extra args and gets

local FS = require('fs')
local Timer = require('timer')
local Table = require('table')
local Math = require('math')

-- Override these in your app
local Kernel = {
  cache_lifetime = 1000,
  helpers = {
    -- Override this in your framework for custom behavior
    X = function (value, name, filename, offset)
      if not(type(value) == "string" or type(value) == "number") then
        error("{{" .. name .. "}} can't be a " .. type(value) .. " in " .. filename .. "(char " .. offset .. ")")
      end
      return value
    end
  },
};


-- Load a file from disk and compile into executable template
local function compile(filename, callback)
  FS.readFile(filename, function (err, source)
    if err then return callback(err) end
    local template;
    local tokens = Kernel.tokenizer(source)
    -- p("tokens", tokens)
    tokens = Kernel.parser(tokens, source, filename)
    -- p("parsed", tokens)
    local code = [[
local Table = require('table')
local this = require(']] .. __filename .. [[').helpers
setmetatable(this,{__index=_G})
return ]] .. Kernel.generator(tokens, filename)
    -- p("code")
    -- print(code)
    local chunk, err = loadstring(code, filename .. ".lua")
    if err then
      return callback(err)
    end
    local real = chunk()
    callback(nil, function (locals, callback)
      local success, err = pcall(function ()
        real(locals, callback)
      end)
      if not success then callback(err) end
    end)
  end)
end


-- A caching and batching wrapper around compile.
local templateCache = {}
local templateBatch = {}
function Kernel.compile(filename, callback)
  -- Check arguments
  if not (type(filename) == 'string') then error("First argument to Kernel must be a filename") end
  if not (type(callback) == 'function') then error("Second argument to Kernel must be a function") end

  -- Check to see if the cache is still hot and reuse the template if so.
  if templateCache[filename] then
    callback(nil, templateCache[filename])
    return
  end
  
  -- Check if there is still a batch in progress and join it.
  if templateBatch[filename] then
    Table.insert(templateBatch[filename], callback)
    return
  end

  -- Start a new batch, call the real function, and report.
  local batch = {callback}
  templateBatch[filename] = batch
  compile(filename, function (err, template)

    -- We don't want to cache in case of errors
    if not err and Kernel.cache_lifetime > 0 then
      templateCache[filename] = template
      -- Make sure cached values expire eventually.
      Timer.setTimeout(Kernel.cache_lifetime, function ()
        templateCache[filename] = nil
      end)
    end

    -- The batch is complete, clear it out and execute the callbacks.
    templateBatch[filename] = nil
    for i, callback in ipairs(batch) do
      callback(err, template)
    end

  end)

end

-- Helper to show nicly formattet error messages with full file position.
local function getPosition(source, offset, filename)
  local line = 0
  local position = 0
  local last = 0
  
  function match()
    position = source:find("\n", position + 1)
    return position
  end
  while match() do
    last = position
  end
  return "(" .. filename .. ":" .. line .. ":" .. (offset - last) .. ")"
end

local function stringify(source, token)
  return source:sub(token.start, token.stop)
end

-- Escape any lua string as a long string
local function string_escape(string)
  local pos = 0
  local found = {}
  local max = 0
  function match()
    local m = {string:find("([%[%]])(=*)%1", pos)}
    if m[4] then
      found[#m[4]] = true
      while found[max] do max = max + 1 end
      pos = m[2]
      return true
    end
  end
  while match() do end
  local r = ("="):rep(max)
  return "[" .. r .. "[" .. string .. "]" .. r .. "]"
end

function Kernel.generator(tokens, filename)
  local length = #tokens
  local left = length

  -- Shortcut for static sections
  if #tokens == 1 and tokens[1].simple and #tokens[1] == 1 and type(tokens[1][1]) == "string" then
    return "function(locals, callback)\n  callback(nil, " .. string_escape(tokens[1][1]) .. ")\nend"
  end
  
  -- Reduce counters for simple tokens
  for i, token in ipairs(tokens) do
    if token.simple then
      left = left - 1
    end
  end
  
  local program_head = [[
function(locals, callback)
  local parent = this
  local this = setmetatable({}, {__index = function (table, key)
    return locals[key] or parent[key]
  end})
  local parts = {}
  local left = ]] .. (left + 1) .. "\n" .. [[
  local done]] .. "\n" .. (left > 0 and [[
  local function error(err)
    if done then return end
    done = true
    callback(err)
  end
  local function check()
    if done then return end
    left = left - 1
    if left == 0 then
      done = true
      callback(nil, Table.concat(parts))
    end
  end]] or "") .. [[
  local function fn()
]]
  local program_tail = [[
  end
  setfenv(fn, this)
  fn()
  left = left - 1
  if left == 0 and not done then
    done = true
    callback(nil, Table.concat(parts))
  end
end
]]
  local generated = {}
  for i, token in ipairs(tokens) do
    if token.simple then
      local parts = {}
      for j, part in ipairs(token) do
        if type(part) == "string" then
          Table.insert(parts, string_escape(part))
        else
          Table.insert(parts, "X(" .. part.name .. "," .. string_escape(part.name) .. "," .. string_escape(filename) .. "," .. part.start .. ")")
        end
      end
      Table.insert(generated, "parts[" .. i .. "]=" .. Table.concat(parts, '..'))
    elseif token.contents or token.args then
      local args = (token.args and #token.args > 0) and (token.args .. ",") or ""
      if token.contents then args = args .. Kernel.generator(token.contents, filename) .. "," end
      Table.insert(generated, token.name .. "(" .. args .. "function(err, result)\n  if err then return error(err) end\n  parts[" .. i .. "]=result\n  check()\nend)")
    else
      error("This shouldn't happen!")
    end
  end
  return program_head .. Table.concat(generated, "\n") .. "\n" .. program_tail;
end

function Kernel.parser(tokens, source, filename)
  local parts = {}
  local open_stack = {}
  local i
  local l
  local simple
  for i, token in ipairs(tokens) do
    if type(token) == "string" then
      if simple then
        Table.insert(simple, token)
      else
        simple = {simple=true,token}
        Table.insert(parts, simple)
      end
    elseif token.open then
      simple = nil
      token.parent = parts
      Table.insert(parts, token)
      parts = {}
      token.contents = parts
      Table.insert(open_stack, token)
    elseif token.close then
      simple = nil
      local top = Table.remove(open_stack)
      if not top then
        error("Unexpected closer " .. stringify(source, token) .. " " .. getPosition(source, token.start, filename))
      elseif not top.name == token.name then
        error("Expected closer for " .. stringify(source, top) .. " but found " .. stringify(source, token) .. " " .. getPosition(source, token.start, filename))
      end
      parts = top.parent
      top.parent = nil
      top.open = nil
    else
      if token.args then
        simple = nil
        Table.insert(parts, token)
      else
        if simple then
          Table.insert(simple, token)
        else
          simple = {simple=true,token}
          Table.insert(parts, simple)
        end
      end
    end
  end
  if #open_stack > 0 then
    local top = Table.remove(open_stack)
    error("Expected closer for " .. stringify(source, top) .. " but reached end " .. getPosition(source, top.stop, filename))
  end
  return parts
end


-- Pattern to match all template tags. Allows balanced parens within the arguments
-- Also allows basic expressions in double {{tags}} with balanced {} within
local patterns = {
  tag = "{([#/]?)([%a_][%a%d_.]*)}",
  call = "{([#]?)([%a_][%a%d_.]*)(%b())}",
  raw = "{(%b{})}",
}

-- This lexes a source string into discrete tokens for easy parsing.
function Kernel.tokenizer(source)
  local parts = {}
  local position = 0
  local match

  function findMatch()
    local min = Math.huge
    local kind
    for name, pattern in pairs(patterns) do
      local m = {source:find(pattern, position)}
      if m[1] and m[1] < min then
        min = m[1]
        match = m
        kind = name
      end
    end
    if not kind then return end
    match.kind = kind
    return true
  end

  while findMatch() do
    local start = match[1]

    if start - 1 > position then -- Raw text was before this tag
      parts[#parts + 1] = source:sub(position + 1, start - 1)
    end

    -- Move search to after tag match
    position = match[2]
    
    -- Create a token and tag the position in the source file for error reporting.
    local obj = { start = start, stop = position }
    
    if match.kind == "raw" then -- Raw expression
      obj.name = match[3]:sub(2, #match[3]-1)
    else
      if match[3] == "#" then
        obj.open = true
      elseif match[3] == "/" then
        obj.close = true
      end
      obj.name = match[4]
      if match.kind == "call" then -- With arguments
        obj.args = match[5]:sub(2,#match[5]-1)
      end
    end
    
    parts[#parts + 1] = obj
    
  end
  
  if #source > position then -- There is raw text left over
    parts[#parts + 1] = source:sub(position + 1)
  end

  return parts
end

return Kernel


