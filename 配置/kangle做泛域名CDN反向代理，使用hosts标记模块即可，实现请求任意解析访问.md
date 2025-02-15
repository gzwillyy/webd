


kangle做泛域名CDN反向代理，使用hosts标记模块即可，实现请求任意解析访问


![alt text](./image/泛域名CDN.png)

对照图填入即可，然后所有请求将会反向代理到那个IP地址。

图中那个0可以改成10秒，使用长连接，性能更高。

增强版匹配80和443域名生效，其他端口不进行反代
https://bbs.itzmx.com/thread-98670-1-1.html