--------------------------------------------------------------------------
-- This module is a luajit ffi binding for the postgresql api 
-- with a spacial emphasis on the non blocking functions. 
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

PSqlConnection = {}
local PSqlConnection_mt = { __index = PSqlConnection }

local ffi = require("ffi")
local libpq = nil

--definitions of the c api
--se http://www.postgresql.org/docs/9.2/static/libpq-async.html
ffi.cdef[[
typedef struct PGconn_s PGconn;
typedef struct PGresult_s PGresult;

typedef enum
{
	PGRES_POLLING_FAILED = 0,
	PGRES_POLLING_READING,		/* These two indicate that one may	  */
	PGRES_POLLING_WRITING,		/* use select before polling again.   */
	PGRES_POLLING_OK
} PostgresPollingStatusType;

typedef enum
{
	PGRES_EMPTY_QUERY = 0,		/* empty query string was executed */
	PGRES_COMMAND_OK,			/* a query command that doesn't return
								 * anything was executed properly by the
								 * backend */
	PGRES_TUPLES_OK,			/* a query command that returns tuples was
								 * executed properly by the backend, PGresult
								 * contains the result tuples */
	PGRES_COPY_OUT,				/* Copy Out data transfer in progress */
	PGRES_COPY_IN,				/* Copy In data transfer in progress */
	PGRES_BAD_RESPONSE,			/* an unexpected response was recv'd from the
								 * backend */
	PGRES_NONFATAL_ERROR,		/* notice or warning message */
	PGRES_FATAL_ERROR,			/* query failed */
	PGRES_COPY_BOTH,			/* Copy In/Out data transfer in progress */
	PGRES_SINGLE_TUPLE			/* single tuple from larger resultset */
} ExecStatusType;

typedef enum
{
	CONNECTION_OK,
	CONNECTION_BAD,
	/* Non-blocking mode only below here */

	/*
	 * The existence of these should never be relied upon - they should only
	 * be used for user feedback or similar purposes.
	 */
	CONNECTION_STARTED,			/* Waiting for connection to be made.  */
	CONNECTION_MADE,			/* Connection OK; waiting to send.	   */
	CONNECTION_AWAITING_RESPONSE,		/* Waiting for a response from the
										 * postmaster.		  */
	CONNECTION_AUTH_OK,			/* Received authentication; waiting for
								 * backend startup. */
	CONNECTION_SETENV,			/* Negotiating environment. */
	CONNECTION_SSL_STARTUP,		/* Negotiating SSL. */
	CONNECTION_NEEDED			/* Internal state: connect() needed */
} ConnStatusType;

PGconn *PQconnectStart(const char *conninfo);

//Returns the status of the connection.
ConnStatusType PQstatus(const PGconn *conn);

PostgresPollingStatusType PQconnectPoll(PGconn *conn);

int PQsetnonblocking(PGconn *conn, int arg);

int PQsendQuery(PGconn *conn, const char *command);

char *PQerrorMessage(const PGconn *conn);

int PQconsumeInput(PGconn *conn);

int PQisBusy(PGconn *conn);

PGresult *PQgetResult(PGconn *conn);

ExecStatusType PQresultStatus(const PGresult *res);

//Returns the number of rows (tuples) in the query result.
int PQntuples(const PGresult *res);

//Returns the number of columns (fields) in each row of the query result. 
int PQnfields(const PGresult *res);

//Returns the column name associated with the given column number. Column numbers start at 0.
//The caller should not free the result directly. 
//It will be freed when the associated PGresult handle is passed to PQclear.
char *PQfname(const PGresult *res, int column_number);

//Returns a single field value of one row of a PGresult. 
//Row and column numbers start at 0. The caller should not 
//free the result directly. It will be freed when the associated 
//PGresult handle is passed to PQclear. 
char *PQgetvalue(const PGresult *res, int row_number, int column_number);

//Tests a field for a null value. Row and column numbers start at 0. 
int PQgetisnull(const PGresult *res, int row_number, int column_number);

//Returns the actual length of a field value in bytes. Row and column numbers start at 0.
int PQgetlength(const PGresult *res, int row_number, int column_number);

//Returns the actual length of a field value in bytes. Row and column numbers start at 0.
int PQgetlength(const PGresult *res, int row_number, int column_number);

//PQescapeLiteral escapes a string for use within an SQL command.
//This memory should be freed using PQfreemem() when the result is no longer needed.
char *PQescapeLiteral(PGconn *conn, const char *str, size_t length);

void PQfreemem(void *ptr);

//Frees the storage associated with a PGresult. 
void PQclear(PGresult *res);

//Closes the connection to the server. Also frees memory used by the PGconn object.
void PQfinish(PGconn *conn);

//returns the filedescriptor for this connection
int PQsocket(PGconn *conn);
]]


--[[Loads the shared library of postgres
    libpath is the path to the library (ie. the .so or .dll) of postgres
    defaults to "/usr/lib/libpq.so.5" if omitted
]]
function PSqlConnection.init(libpath)
  libpq = ffi.load(libpath or "/usr/lib/libpq.so.5")
end


--[[Creates a new connection to a Postgres SQL in
    async mode. The string conninfo is passed to 
    PQconnectStart.
]]
function PSqlConnection.newAsync(conninfo)
	local new_inst = {}
	setmetatable( new_inst, PSqlConnection_mt )
	assert(conninfo)
	new_inst.PGconn = ffi.gc(libpq.PQconnectStart(conninfo), libpq.PQfinish)
	return new_inst
end


--[[Returns the dialUpState 
]]
function PSqlConnection:dialUpState()
    assert(libpq.PQconnectPoll(self.PGconn) ~= "PGRES_POLLING_FAILED", self:getError())
    return libpq.PQstatus(self.PGconn)
end


--[[Returns the last errormessage
]]
function PSqlConnection:getError()
    return ffi.string(libpq.PQerrorMessage(self.PGconn))
end


--[[Sends a query to the server 
    All old data has to be collecet befor an new 
    query can be send (getAvailable returns nil)
    
    Node:   Multiple querys in one will be treated as one transaction.
            read PostgreSQL doc 31.3.1
]]
function PSqlConnection:sendQuery(query)
  	assert(not self.queryInProcess, "Error: Old query isn't finished")
	local ret = libpq.PQsendQuery(self.PGconn, query)
	if ret == 0 then
		error(self:getError())
	end
    self.queryInProcess = true
end


--[[Returns true if getAvailable can be called without
    blocking
]]
function PSqlConnection:readReady()
	local ret = libpq.PQconsumeInput(self.PGconn)
	if ret == 0 then
		error(self:getError())
	end
	return libpq.PQisBusy(self.PGconn) == 0
end


--[[Returns a tables of all avilable data or nil if no more data is availible
  The table is structured with the column names in row 0 and the data afterwards
  ie. [1][1] is the first row in the first column and [0][1] is the name of that column
    |     1         |       2       | ...
-------------------------------------------
  0 | column name 1 | column name 2 | ...
--------------------------------------------
  1 | data column 1 | data  ......
]]
function PSqlConnection:getAvailable()
    local result = libpq.PQgetResult(self.PGconn)
    if result ~= nil then
        local status  = libpq.PQresultStatus(result)
        local rows    = libpq.PQntuples(result)
        local columns = libpq.PQnfields(result)
        
        local tab = {}
        tab[0] = {}
        
        for j = 1, columns do
            tab[0][j] = ffi.string(libpq.PQfname(result, j-1))
        end
        
        for i = 1, rows do
            tab[i] = {}
            
            for j = 1, columns do
                local value = nil
                if 0 == libpq.PQgetisnull(result, i-1, j-1) then
                    value = ffi.string(
                                libpq.PQgetvalue(result, i-1, j-1), 
                                libpq.PQgetlength(result, i-1, j-1)
                            )
                end
                 
                tab[i][j] = value 
            end
        end
        
        libpq.PQclear(result)

        return tab, status
    else
        self.queryInProcess = nil
        return nil
    end
end

--[[Returns the socketdescriptor
]]
function PSqlConnection:getSocket()
    return libpq.PQsocket(self.PGconn)
end
 

--[[Returns a escaped version of the string than can be savely
    used in a query without danger of SQL injection
]]
function PSqlConnection:escape(data)
    local strData = tostring(data)
    local result = libpq.PQescapeLiteral(self.PGconn, strData, #strData)
    if result ~= nil then
        local strResult = ffi.string(result)
        libpq.PQfreemem(result)      
        return strResult
    else
        error(self:getError())
    end
end

return PSqlConnection
