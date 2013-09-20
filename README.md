Catke : lua web框架
==========================

使用 [luvit](http://luvit.io) 作为底层，性能强劲的 web 框架

### 性能测试

cpu  : 双核 i5(1.7G) 
内存 : 512 MB
OS   : centos 6.2(32位， vbox 虚拟)

连接 postgres 表（有数据2条），执行：

```sql
select * from cms_table;
```

ab 测试：

```sh
ab -n 10000 -c 200 http://127.0.0.1/
``

结果

```
Server Software:        Luvit
Server Hostname:        127.0.0.1
Server Port:            80

Document Path:          /
Document Length:        0 bytes

Concurrency Level:      200
Time taken for tests:   5.281 seconds
Complete requests:      10000
Failed requests:        0
Write errors:           0
Total transferred:      711704 bytes
HTML transferred:       0 bytes
Requests per second:    1893.46 [#/sec] (mean)
Time per request:       105.627 [ms] (mean)
Time per request:       0.528 [ms] (mean, across all concurrent requests)
Transfer rate:          131.60 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    2   1.7      2      12
Processing:    67  102  23.2     97     285
Waiting:       53   92  23.9     86     284
Total:         68  105  23.7     99     295

Percentage of the requests served within a certain time (ms)
  50%     99
  66%    106
  75%    112
  80%    115
  90%    123
  95%    143
  98%    196
  99%    215
 100%    295 (longest request)
```

