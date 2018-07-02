#失误运行此文件时，exit命令 立即退出
exit 1

----2055项目----

物理机部署服务脚本调用说明

#安装
/opt/installScript是脚本的存放路径
/opt/installScript/dbInstall.sh
/opt/installScript/appInstall.sh 数据库服务IP 模式名称
/opt/installScript/mediaInstall.sh 本主机IP 信令服务IP
/opt/installScript/sipInstall.sh 本主机IP 应用服务IP 媒体服务IP:5093,媒体服务IP:5093...
/opt/installScript/conInstall.sh 数据库服务IP
/opt/installScript/datasyncInstall.sh 本主机IP 数据库服务IP 模式名称
/opt/installScript/upgradeInstall.sh 数据库服务IP
/opt/installScript/amqInstall.sh 节点名称P
openldap:
/opt/installScript/ldap.sh 1-255数字 192.168.1.1-192.168.1.2-192.168.1.3
vtserver:
/opt/installScript/vtserver.sh 本主机IP

集中配置完后重启服务
/opt/installScript/appInstall.sh restart
/opt/installScript/mediaInstall.sh restart
/opt/installScript/sipInstall.sh restart
/opt/installScript/datasyncInstall.sh restart

#修改IP
/opt/installScript/updateIP.sh 旧IP 新IP 新网关
数据库和amq只运行updateIP.sh，不能运行安装脚本
其它的六个安装脚本运行方式是在安装跟的参数最后再加上一个 updateIP 标识
vtserver:
/opt/installScript/vtserver.sh 本主机IP updateIP

#升级
数据库不用运行安装脚本
媒体信令升级不跟参数运行
sh /opt/installScript/mediaInstall.sh
sh /opt/installScript/sipInstall.sh
其它五个脚本加 update
如 /opt/installScript/datasyncInstall.sh 本主机IP 数据库服务IP 模式名称 update
vtserver:
/opt/installScript/vtserver.sh 本主机IP update

#恢复单个服务
数据库：/opt/installScript/dbInstall.sh restart
媒体：/opt/installScript/mediaInstall.sh 本主机IP 信令服务IP updateCode code
信令：/opt/installScript/sipInstall.sh 本主机IP 应用服务IP 媒体服务IP:5093,媒体服务IP:5093... updateCode code
其它七个的运行方式和升级一样

#依托骨干恢复
/opt/installScript/sipInstall.sh updateCode code
/opt/installScript/mediaInstall.sh updateCode code


#备份
应用
/opt/installScript/backup.sh app 时间
数据库
/opt/installScript/backup.sh db 时间
信令
/opt/installScript/backup.sh sip 时间
媒体
/opt/installScript/backup.sh media 时间
集中
/opt/installScript/backup.sh conf 时间
同步
/opt/installScript/backup.sh sync 时间
升级
/opt/installScript/backup.sh upgrade 时间
amq
/opt/installScript/backup.sh amq 时间
vtserver
/opt/installScript/backup.sh vtserver 时间

#还原
/opt/installScript/backup.sh restore 应用标识 时间

#卸载
sh /opt/installScript/mediaInstall.sh uninstall

