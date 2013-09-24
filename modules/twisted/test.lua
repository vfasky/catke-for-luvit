#!/usr/bin/env luvit

local table = require 'table'
local timer = require 'timer'
local twisted = require "./init.lua"
local bourbon = require './bourbon'

local tests = {}

tests.test_sync = function(test, asserts)
  local f = twisted.inline_callbacks(function()
    local var = 1
    var = twisted.yield(var+1)
    var = twisted.yield(var+1)
    return {nil, var}
  end)

  f(function(err, res)
    asserts.equal(err, nil, "got err")
    test.done()
  end)
end

tests.test_err = function(test, asserts)
  local f = twisted.inline_callbacks(function()
    asdf()
  end)

  f(function(err, res)
    asserts.not_nil(err, 'need an err')
    test.done()
  end)
end

tests.test_async = function(test, asserts)
  local f = twisted.inline_callbacks(function()
    local func = function(cb)
      timer.setTimeout(10, cb, 2)
    end
    local res = twisted.yield(func)
    asserts.equal(res, 2)
  end)

  f(function(err, res)
    asserts.equal(err, nil)
    test.done()
  end)
end

tests.test_async_with_args = function(test, asserts)
  local f = twisted.inline_callbacks(function()
    local func = function(a, b, c, cb)
      timer.setTimeout(10, cb, c)
    end
    local res = twisted.yield(func, 1, nil, 3)
    asserts.equal(res, 3)
  end)

  f(function(err, res)
    asserts.equal(err, nil)
    test.done()
  end)
end

tests.test_sentinel = function(test, asserts)
  local f = twisted.inline_callbacks(function()
    local func = function(a, b, cb)
      asserts.not_nil(cb, 'should be a function')
      timer.setTimeout(10, cb, 2)
    end
    local res = twisted.yield(func, 1, nil, twisted.SENTINEL)
    asserts.equal(res, 2)
  end)

  f(function(err, res)
    asserts.equal(err, nil)
    test.done()
  end)
end

tests.test_return = function(test, asserts)
  local f = twisted.inline_callbacks(function()
    local func = function(a, cb)
      asserts.not_nil(cb, 'should be a function')
      timer.setTimeout(10, cb, a)
    end
    local res = twisted.yield(func, 1, twisted.SENTINEL)
    return {nil, res}
  end)

  f(function(err, res)
    asserts.equal(err, nil)
    asserts.equal(res, 1)
    test.done()
  end)
end

bourbon.run(tests)