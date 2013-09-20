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
ab -n 10000 -c 900 http://127.0.0.1/
```

结果:

```
This is ApacheBench, Version 2.3 <$Revision: 655654 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 127.0.0.1 (be patient)
Completed 1000 requests
Completed 2000 requests
Completed 3000 requests
Completed 4000 requests
Completed 5000 requests
Completed 6000 requests
Completed 7000 requests
Completed 8000 requests
Completed 9000 requests
Completed 10000 requests
Finished 10000 requests


Server Software:        Luvit
Server Hostname:        127.0.0.1
Server Port:            80

Document Path:          /
Document Length:        0 bytes

Concurrency Level:      900
Time taken for tests:   6.216 seconds
Complete requests:      10000
Failed requests:        0
Write errors:           0
Total transferred:      710000 bytes
HTML transferred:       0 bytes
Requests per second:    1608.85 [#/sec] (mean)
Time per request:       559.405 [ms] (mean)
Time per request:       0.622 [ms] (mean, across all concurrent requests)
Transfer rate:          111.55 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    8  15.5      3      65
Processing:   156  530 107.2    535    1149
Waiting:      137  517 108.4    522    1148
Total:        219  537 100.6    538    1181

Percentage of the requests served within a certain time (ms)
  50%    538
  66%    553
  75%    561
  80%    567
  90%    587
  95%    608
  98%    935
  99%   1069
 100%   1181 (longest request)

```

