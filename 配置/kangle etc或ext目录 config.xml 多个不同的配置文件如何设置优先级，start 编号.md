


kangle etc或ext目录 config.xml 多个不同的配置文件如何设置优先级，start 编号

start 编号随意，尽量填写50以上，这个是优先级顺序，数值越大，优先级越高（多个相同的配置文件内容以最高的优先级执行），
默认值50，最小值为1，最大值为100000，如果要让配置文件生效，请把start 编号写为51

例子
创建一个名为 cache.max.xml 的配置文件内容如下


```
<!--#start 901 -->
<config>
<cache default='1' max_cache_size='1M' max_bigobj_size='10G'/>
</config>
```