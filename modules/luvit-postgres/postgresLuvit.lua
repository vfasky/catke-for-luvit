--------------------------------------------------------------------------
-- This module is a luvit binding for the postgresql api. 
-- 
-- Copyright (C) 2012 Moritz Kühner, Germany.
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--------------------------------------------------------------------------

local postgres = require("./postgresffi")
local timer = require('timer')
local object = require('core').Object
local table = require("table")


--[[Loads the library at POSTGRESQL_LIBRARY_PATH if not nil 
    defaults to "/usr/lib/libpq.so.5".
    
    To use this set the global with a string pointing at the right 
    path befor requiring this library.
]]
postgres.init(POSTGRESQL_LIBRARY_PATH)


--Timeout for the poll timer
local POLLTIMER_INTERVALL = 5


local LuvPostgres = object:extend()

local function callIfNotNil(callback, ...)
    if callback ~= nil then
        callback(...)
    end
end

--[[Constructor the coninfo string is passed to PQconnectStart.
]] 
function LuvPostgres:initialize(coninfo, callback)

    self.con = postgres.newAsync(coninfo)

    --[[ This is an dirty hack to update the connection state. The correct
         solution should watch the socket descriptor and update upon 
         network activity    
    ]]
    self.watcher = timer.setInterval(POLLTIMER_INTERVALL, function()
        local state = self.con:dialUpState()
		
        if 0 == state then
            timer.clearTimer(self.watcher)
            self.established = true
            callIfNotNil(callback)
        elseif 1 == state then
            timer.clearTimer(self.watcher)
            callIfNotNil(callback, self.con:getError())
        end
    end)
end


-- internal function to retrieve a fragment of the result 
local function getFragment(connection)
    local ok, ready = pcall(connection.readReady, connection)
    
    if not ok then
        --error occured
        return nil, ready
    elseif not ready then
        --no input ready
        return {}
    end
    
    local ok, result , status = pcall(connection.getAvailable, connection)
    if not ok then
        --error occured
        return nil, ready
    end
    
    local isOver = false
    if status <= 7 then
        --query is over 
        if connection:getAvailable() ~= nil then
            --internal error occured
            return nil, "Internal binding error. Query is not over!"
        end
        
        if status == 5 or status == 7 then 
            --error occured
            return nil, connection:getError()
        end
        isOver = true
    end

    return result, isOver
end

--[[Sends a query to the sql server

    Callback is called with error and the entire resultset.
    Read postgresffi.getAvailable for a description of the format.
]]
function LuvPostgres:sendQuery(query, callback)
    if not self.established then
        callIfNotNil(callback, "Can't send query. Connection is not established!")
        return
    end
    self.con:sendQuery(query)
    
    local resultAccu = {}
    --[[ This is an dirty hack to update the connection state. The correct
         solution should watch the socket descriptor and update upon 
         network activity    
    ]]
    self.watcher = timer.setInterval(POLLTIMER_INTERVALL, function()
        local result, over = getFragment(self.con)

        if not result then
            timer.clearTimer(self.watcher)
            callIfNotNil(callback, over)
        else
            local cntRow = #result
            for i = 1, cntRow do
                table.insert(resultAccu, result[i])
            end

            if over then
                resultAccu[0] = result[0]
                timer.clearTimer(self.watcher)
                callIfNotNil(callback, nil, resultAccu)
            end
        end
    end)
end

--[[Sends a query to the sql server and returns intermediate results

    Callback is called with error and subset of the result and to mark the end a boolean true.
    Read postgresffi.getAvailable for a description of the format.
]]
function LuvPostgres:sendQueryIntermediate(query, callback)
    if not self.established then
        callIfNotNil(callback, "Can't send query. Connection is not established!")
        return
    end
    self.con:sendQuery(query)
    
    --[[ This is an dirty hack to update the connection state. The correct
         solution should watch the socket descriptor and update upon 
         network activity    
    ]]
    self.watcher = timer.setInterval(POLLTIMER_INTERVALL, function()
        local result, over = getFragment(self.con)
        if not result then
            timer.clearTimer(self.watcher)
            callIfNotNil(callback, over)
        else
            if over then
                timer.clearTimer(self.watcher)
            end        
            callIfNotNil(callback, nil, result, over)
        end
    end)
end


--[[Returns a escaped version of the string than can be savely
    used in a query without danger of SQL injection or nil and 
    a message on error
]]
function LuvPostgres:escape(query)
    local ok, value = pcall(self.con.escape, self.con, query)
    if ok then
        return value
    end
    return nil, value
end



return LuvPostgres
