#!/bin/bash

nodeName=$1
flag=$2


#日志
logFile=/mnt/install.log
if [ "$flag" == "update" ]; then
    echo -e "\n\n#update-amq\n`date`" &>>$logFile
else
    echo -e "\n\n#deploy-amq\n`date`" &>>$logFile
fi

#安装jdk
scriptPath=/opt/installScript
. $scriptPath/javaHome.sh

amqHome=$fxHome/amq

#停止服务
[ -f $amqHome/bin/activemq ] && $amqHome/bin/activemq stop &>>$logFile
amqpid=`ps -ef |grep -v grep |grep '/home/fx/amq' |awk '{print$2}'`
if ! [ "$amqpid" == "" ]; then
    kill -9 $amqpid &>>$logFile
fi
#不安装#######################################--------------------------
exit
########################################--------------------------

#从仓库下载安装包
if [ "$flag" == "update" ]; then
    ##升级
    echo "开始升级amq程序的所有文件" &>>$logFile
    $dcp $hubIP $packages/amq $fxHome/ &>/dev/null
else
    #安装
    echo "开始从 $hubIP 下载amq的安装包" &>>$logFile
    [ -d $amqHome/ ] && rm -rf $amqHome/
    [ $? -eq 0 ] && echo "旧的目录 $amqHome 删除成功！" &>>$logFile
    $dcp $hubIP $packages/amq $fxHome/ &>/dev/null
fi
chmod -R 755 $amqHome


#修改配置文件
if [ $nodeName ]; then
    sed -i "s/brokerName=\"[^\"]*\"/brokerName=\"$nodeName\"/" $amqHome/conf/activemq.xml
else
    echo "没有传入节点名称"
fi


#启动服务
#sh $amqHome/startAmq.sh &>/dev/null
$amqHome/bin/activemq start &>/dev/null
sleep 2
if ps -ef |grep -v grep |grep -q '/home/fx/amq'; then
    echo "amq 启动成功" |tee -a $logFile
else
    echo "amq 启动失败！" |tee -a $logFile
fi


#添加开机自启脚本到rc.local
chmod +x $rcFile

if grep -q 'startAmq.sh' $rcFile; then
    sed -i '/amq服务/,/^$/d' $rcFile
fi

grep -q 'amq服务' $rcFile
if [ $? -ne 0 ]; then
    echo -e "\n#amq服务\nsource /etc/profile\n$amqHome/bin/activemq start" >>$rcFile
    echo "amq服务开机自启添加完成" &>>$logFile
fi

