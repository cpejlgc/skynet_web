作者：LGC
时间：2017年 9月 1日 星期五 09时21分26秒

服务端框架skynet: https://github.com/cloudwu/skynet/wiki 
skynet学习资源：http://skynetclub.github.io/skynet/resource.html
云风的演讲视频： http://gad.qq.com/content/coursedetail?id=467
云风的blog: https://blog.codingnow.com/

基于skynet的web服务
1. 类似nodejs express api
2. 热更新
3. 在web服务上添加websocket支持

集成库
1. cjson
2. dpull的webclient (https://github.com/dpull/lua-webclient)
3. lfs
4. websocket


编译前

ubuntu: sudo apt-get install libcurl4-gnutls-dev libreadline-dev autoconf

centos: sudo yum install libcurl-devel readline-devel  autoconf

编译

Linux: make linux

Mac: make macosx

启动：
./bin/start.sh

后台运行：
./bin/start.sh -D

关闭后台进程：
./bin/start.sh -K

热更新：
./bin/start.sh -U

