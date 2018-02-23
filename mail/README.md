### Centos 配置mailx使用外部smtp发送邮件

### 安装mailx
` yum install mailx`

### 配置mailx

笔者推荐163邮箱，当然，QQ邮箱也是可以的，PS：记得要进邮箱打开SMTP

vi /etc/mail.rc  //如果不存在，则编辑/etc/nail.rc
在文件的末尾加入下面代码，相应帐号密码填写自己的帐号密码
```
set from="xxx@163.com"
set smtp=smtp.163.com
set smtp-auth-user=xxx
set smtp-auth-password=邮箱密码
set smtp-auth=login
```

### 使用mailx发送邮件

发件人名称可不添加，第二步已配置过

假设邮件内容存储于mesg文件中，那么可以用如下2个方法：

` mailx -s "发件人名称  邮件标题" xxx@163.com < mesg`
`cat mesg | mailx -s "发件人名称 邮件标题" xxx@163.com`

多个收件人之间用逗号分隔：

`cat mesg | mailx -s "发件人名称 邮件标题" xxx@163.com,xxx2@163.com,xxx3@163.com`

也可以直接从命令行输入邮件内容：

`mailx -s "发件人名称 邮件标题" xxx@163.com`         ##输入完后回车按Ctrl+D提交发送

`echo  hello word | mailx -v -s " title" xxx3@163.com`

### 踩过的坑

1. 记得要进邮箱打开SMTP
2. 配置好后，记住查看是否打开代理（例如翻墙VPN）,代理可能会导致Telnet不通25端口