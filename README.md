Catke : lua web框架
==========================

使用 [luvit](http://luvit.io) 作为底层，性能强劲的 web 框架


node 已经脱离了刀耕火种的年代，luvit 还是水深火热中 Q^Q

Catke for luvit 是一个简单的 web 框架，让你写 luvit 的时候，不用从头再来

- 静态目录支持
- 路由支持
- 任务队列支持
- 模板引擎
- 异步ORM(Postgres)
- 类 tornado 的协程支持

### ORM:

#### 定义model `models.lua`

```lua
local Postgres = require('catke/web/postgres')
local Mopee    = require('catke/web/mopee')

-- 数据库配置，需指定 libpq 的位置 
Mopee.meta.database = Postgres:new({
	host     = '127.0.0.1',
	dbname   = 'cb',
	user     = '',
	password = '',
	size     = 40 -- 连接数
}, '/usr/lib/libpq.5.dylib')

local exports = {}

exports.Article = Mopee:new('article', {
	cid       = Mopee.IntegerField:new({index = true}),
	title     = Mopee.CharField:new({max_length = 255}),
	time      = Mopee.IntegerField:new({index = true}),
	summarize = Mopee.TextField:new({default = '[]'}),
	comment   = Mopee.TextField:new({default = '[]'}),
	content   = Mopee.TextField:new({null = true})
})


exports.Keyword = Mopee:new('keyword', {
	title = Mopee.CharField:new({max_length = 255})
})

exports.ArticleKeyword = Mopee:new('article_keyword', {
	keyword = Mopee.ForeignKey:new(exports.Keyword),
	article = Mopee.ForeignKey:new(exports.Article),
	hasid   = Mopee.CharField:new({max_length = 30, unique = true})
})

return exports

```

### 查询

``` lua
local Article        = require('./models').Article
local Keyword        = require('./models').Keyword
local ArticleKeyword = require('./models').ArticleKeyword

-- 查询多条
Article:select(Article.id, Article.title, Article.summarize)
	   :where(Article.id.Gt(10)) -- 大于10
	   :order_by(Article.cid.Desc())
	   :page(1, 10)
	   :all(function(data)
			p(data)
	   end)

-- 查询单条
Article:select()
       :where(Article.id.Eq(id))
	   :get(function(article)
	   		p(article)
			-- 关联查询 
			Keyword:select(ArticleKeyword.id, Keyword.title)
				   :join(ArticleKeyword.article.Eq(article))
				   :order_by(ArticleKeyword.id.Asc())
				   :all(function(data)
					    p(data)
				   end)

	   end)

```

### 添加, 修改, 删除

``` lua
local os       = require('os')
local Article  = require('./models').Article

-- 添加
local article = Article({
	cid = 1,
	title = 'test',
	time = os.time(),
	summarize = '[]',
	content = 'content',
})

article:save(function(article)
	p(article.id)
end)

-- 修改
Article:select()
       :where(Article.cid.Eq(1))
	   :get(function(article)
			article.title = 'test2'
			article:save(function(article)
				p(article.id)
			end)
		end)

-- 删除
Article:select()
       :where(Article.cid.Eq(1))
	   :get(function(article)
			article:delete(function(res)
				p(res)
			end)
		end)

```

### 性能测试

- cpu  : 双核 i5(1.7G) 
- 内存 : 512 MB
- OS   : centos 6.2(32位， vbox 虚拟)

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

