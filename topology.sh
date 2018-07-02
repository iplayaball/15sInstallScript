#!/bin/bash

logFile=/mnt/install.log
exec 1>>$logFile
thisDir=$(cd $(dirname $0) && pwd )

action=$1
localIP=$2
switchIP=$3

#服务相关变量
fxHome=/home/fx
topologyCfg=/usr/local/etc/topology/getNetworkTopology.conf


#日志
if [ $action == "install" ]; then
    echo -e "\n\n#install-getNetworkService\n`date`"
elif [ $action == "update" ]; then
    echo -e "\n\n#update-getNetworkService\n`date`"
fi
echo ***$0 $*

#运行脚本对服务器进行一些初始化
. $thisDir/tools/init.sh

#添加系统服务
chmod +x $thisDir/services/getNetworkService
rsync -av $thisDir/services/getNetworkService /etc/init.d/
chkconfig --add getNetworkService

#停止服务
service getNetworkService stop
if [ $? -ne 0 ]; then
    echo "网络拓扑分发程序停止失败！" >&2
    exit 3
fi

if [ $action == 'install' ]; then
    #下载安装包
    $dcp $hubIP $packages/topology-1.0-1.x86_64.rpm $fxHome/
    rpm -ivh $fxHome/topology-1.0-1.x86_64.rpm &>>$logFile

    #修改配置文件
    sed -i "s/^ip_addr\s*=.*/ip_addr = $switchIP/;
            s/^ip_local_to_addr00\s*=.*/ip_local_to_addr00 = $localIP/;
            s/^ip_local_to_addr01\s*=.*/ip_local_to_addr01 = $localIP/;
            s/^push_func01\s*=.*/push_func01 = 1/;
            " $topologyCfg

    echo "------配置文件修改了的配置信息如下："
    sed -n "/^ip_addr/p;
            /^ip_local_to_addr00/p;
            /^ip_local_to_addr01/p;
            /^push_func01/p;
            " $topologyCfg
    echo "--------------------------------"
elif [ $action == 'update' ]; then
    #$dcp $hubIP $packages/Message/1409message.jar $messageHome/
    echo 'update pass'
fi

#启动服务
service getNetworkService start
if [ $? -eq 0 ]; then
    echo "网络拓扑分发程序启动成功" >&2
fi

