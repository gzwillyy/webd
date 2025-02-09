
kangle 用请求控制中的url模块做正则表达式屏蔽IP地址直接访问的方法，必须使用域名

目标拒绝
请求控制url匹配模块

```
(http|https)://([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)
```

配置文件例如，用配置文件方案可以丢弃不响应403
登录ssh，进入配置文件目录

```
cd /vhs/kangle/ext
```

创建一个名为 noip.xml 的文件

```
vi noip.xml
```

内容如下

```
<config>
<request >
<table name='BEGIN'>
                        <chain  action='drop' >
                                <acl_url  nc='1'><![CDATA[(http|https)://([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)]]></acl_url>
                        </chain>
</table>
</request >
</config>
```


保存文件后，允许以下命令生效

```
/vhs/kangle/bin/kangle -r
```