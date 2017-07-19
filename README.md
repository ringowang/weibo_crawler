# 微博爬虫玩具

## 实现方式

* Nokiogi 实现内容抓取
* 数据存在SQLite里面
* Sinatra 做的展示(样式Bootstrap)
* whenever 完成定时爬虫
* rest-client 登陆微博
* redis 维护一个最新发表时间，防止重复抓取




## 使用方式

```
# 安装需要的gem
bundle install

# 启动Crontab定时任务
whenever -i 
whenever -w

# 启动Sinatra
rackup
```