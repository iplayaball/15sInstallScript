#!/bin/bash

dbIP=$1
flag=$2


#日志
logFile=/mnt/install.log
if [ "$flag" == "updateIP" ]; then
    echo -e "\n\n#updateIP-con\n`date`" &>>$logFile
elif [ "$flag" == "update" ]; then
    echo -e "\n\n#update-con\n`date`" &>>$logFile
else
    echo -e "\n\n#deploy-con\n`date`" &>>$logFile
fi

#安装jdk
scriptPath=/opt/installScript
. $scriptPath/javaHome.sh

if [ $dbIP ]; then
    iptest $dbIP
fi

jiZhong_home=$fxHome/jiZhong_jetty
jiZhong_sh=$jiZhong_home/bin/jetty.sh


#停止服务
[ -f $jiZhong_sh ] && $jiZhong_sh stop &>>$logFile
sleep 3
conPid=`ps -ef |grep -v grep |grep '/home/fx/jiZhong_jetty' |awk '{print$2}'`
if ! [ "$conPid" == "" ]; then
    kill $conPid &>>$logFile
    sleep 3

    conPid=`ps -ef |grep -v grep |grep '/home/fx/jiZhong_jetty' |awk '{print$2}'`
    if ! [ "$conPid" == "" ]; then
        kill -9 $conPid &>>$logFile
        sleep 3

        conPid=`ps -ef |grep -v grep |grep '/home/fx/jiZhong_jetty' |awk '{print$2}'`
        if ! [ "$conPid" == "" ]; then
            echo '停止集中失败！' |tee -a $logFile
            exit 3
        fi
    fi
fi


#从仓库下载安装包
if [ "$flag" == "updateIP" ]; then
    #改IP
    echo "开始修改集中配置文件中的IP" &>>$logFile
elif [ "$flag" == "update" ]; then
    #升级
    echo "开始升级配置程序的所有文件" &>>$logFile
    $dcp $hubIP $packages/jiZhong_jetty $fxHome/ &>/dev/null
    rm -rf $jiZhong_home/work/*
else
    #安装
    echo "开始从 $hubIP 下载集中配置的安装包" &>>$logFile
    [ -d $jiZhong_home/ ] && rm -rf $jiZhong_home/
    [ $? -eq 0 ] && echo "旧的目录 $jiZhong_home 删除成功" &>>$logFile
    $dcp $hubIP $packages/jiZhong_jetty $fxHome/ &>/dev/null
fi
chmod -R 755 $jiZhong_home


#修改配置文件
if [ $dbIP ]; then
    iptest $dbIP

    echo "传入的IP是 dbIP:$dbIP" &>>$logFile
    setIP $jiZhong_home/config/cascade.properties $dbIP
fi


#启动服务
$jiZhong_sh restart &>/dev/null
sleep 3
if ps -ef |grep -v grep |grep -q '/home/fx/jiZhong_jetty'; then
    echo "启动集中服务成功" |tee -a $logFile
else
    echo "启动集中服务失败！" |tee -a $logFile
fi


#添加开机自启脚本到rc.local
grep -q '集中服务' $rcFile
if [ $? -ne 0 ]; then
    echo -e "\n#集中服务\nsource /etc/profile\n$jiZhong_sh restart" >>$rcFile
    echo "集中服务开机自启添加完成" &>>$logFile
fi
#赋予执行权限在最后,可能不存在此文件,最后在赋予执行权限
chmod +x $rcFile

#服务器直接断电的情况下，jetty的pid文件不会被删除，start不启动jetty
#以前部署的 start 改成 restart
sed -i 's/jetty.sh start/jetty.sh restart/' $rcFile

