# natpierce-docker
[gituhub仓库地址](https://github.com/XingHeYuZhuan/natpierce-docker "https://github.com/XingHeYuZhuan/natpierce-docker")
皎月连docker扩展
## 镜像介绍
皎月连扩展镜像  
修改内容： 
增加时区文件，默认时区为Shanghai   
持久化文件，存储在存储卷，请自行查看  
web端口号支持永久更改，更改环境变量webdkh即可,默认值为33272   
新增版本更新选择,环境变量update的值true或者false,决定是否需要保持最新版   
环境变量customversion是手动决定的版本号,这只在update为false生效   
更改镜像组成，使在镜像不变的情况下，更新最新的皎月连版本，你只需要重启镜像即可  

### docker run：  
使用前请确认已安装docker
```
docker run -d --name natpierce \
    --restart=always \
    --privileged \
    --net=host \
    -v natpierce_data:/natpierce \
    xiyu505/natpierce:latest  
```
### docker compose：  
使用前请确认已安装docker compose
```
services:
  natpierce:
    image: xiyu505/natpierce:latest
    container_name: natpierce
    restart: always
    privileged: true
    network_mode: host
    environment:
      webdkh: "33272"
      update: "true"
      customversion: "null"
    volumes:
      - data:/natpierce
volumes:
  data:
```  