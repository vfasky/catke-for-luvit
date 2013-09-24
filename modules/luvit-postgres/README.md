luvit-postgres
==============

This module is a luvit binding for the postgresql api. 
It also includes a luajit ffi binding for the postgresql api with a spacial emphasis on the non blocking functions witch can be used without luvit.

This module is an early experimental stage. I welcome all (constructive) feedback.

Example
==============

    local postgresLuvit = require('postgresLuvit')
  
    p("Testing postgresLuvit")
  
    dbcon = postgresLuvit:new("dbname=test", function(err)
        assert(not err, err)
        dbcon:sendQuery("DROP TABLE IF EXISTS test",function(err, res)
            assert(not err, err)
            
            dbcon:sendQuery("CREATE TABLE test ( id bigserial primary key, node text, addedAt timestamp)",function(err, res)
                assert(not err, err)
                
                dbcon:sendQuery("INSERT INTO test (node, addedAt) VALUES (" .. 
                                    dbcon:escape([["); DROP TABLE test; --]]) ..
                                    ", now() )",function(err, res)
                    assert(not err, err)
                    
                    dbcon:sendQuery("SELECT * FROM test",function(err, res)
                        assert(not err, err)
                        p(res)
                    end)
                end)
            end)
        end)
    end)
