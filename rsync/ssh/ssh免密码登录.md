### ssh 免密码登录

1. 客户端生成秘钥
2. 客户端上传秘钥到服务端 以及加密码添加到ssh-agent
3. 无密码登录

#### 1. 客户端生成秘钥
1. 生成公私钥 

    `ssh-keygen -f /root/.ssh/id_rsa_rsync`

2. 上传公钥到服务端

   `ssh-copy-id -i ~/.ssh/id_rsa_rsync.pub 47.100.14.234`
3. 添加私钥到ssh-agent 无秘登录 
 
   `ssh-add /root/.ssh/id_rsa_rsync`
4. 登录

  - `ssh -p 22 47.100.14.234 -i /root/.ssh/id_rsa_rsync`  
