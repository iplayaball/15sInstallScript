#!/bin/bash

dbIP=$1
flag=$2

#日志
logFile=/mnt/install.log
if [ "$flag" == "updateIP" ]; then
    echo -e "\n\n#updateIP-upgrade\n`date`" &>>$logFile
elif [ "$flag" == "update" ]; then
    echo -e "\n\n#update-upgrade\n`date`" &>>$logFile
else
    echo -e "\n\n#deploy-upgrade\n`date`" &>>$logFile
fi

#安装jdk
scriptPath=/opt/installScript
. $scriptPath/javaHome.sh

shengJi_home=$fxHome/shengJi_jetty
shengJi_sh=$shengJi_home/bin/jetty.sh
shengJi_config=$shengJi_home/config/jdbc.properties


#停止服务
[ -f $shengJi_sh ] && $shengJi_sh stop &>>$logFile
sleep 3
upgPid=`ps -ef |grep -v grep |grep '/home/fx/shengJi_jetty' |awk '{print$2}'`
if ! [ "$upgPid" == "" ]; then
    kill $upgPid &>>$logFile
    sleep 3

    upgPid=`ps -ef |grep -v grep |grep '/home/fx/shengJi_jetty' |awk '{print$2}'`
    if ! [ "$upgPid" == "" ]; then
        kill -9 $upgPid &>>$logFile
        sleep 3

        upgPid=`ps -ef |grep -v grep |grep '/home/fx/shengJi_jetty' |awk '{print$2}'`
        if ! [ "$upgPid" == "" ]; then
            echo '停止升级失败！' |tee -a $logFile
            exit 3
        fi
    fi
fi
#不安装#######################################--------------------------
sed -i '/升级服务/,/shengJi_jetty/d' $rcFile
exit
########################################--------------------------

#从仓库下载安装包
if [ "$flag" == "updateIP" ]; then
    #改IP
    echo "开始修改升级配置文件中的IP" &>>$logFile
elif [ "$flag" == "update" ]; then
    #升级
    echo "开始升级upgrade程序的所有文件" &>>$logFile
    $dcp $hubIP $packages/shengJi_jetty $fxHome/ &>/dev/null
    rm -rf $shengJi_home/work/*
else
    #安装
    echo "开始从 $hubIP 下载升级服务的安装包" &>>$logFile
    [ -d $shengJi_home/ ] && rm -rf $shengJi_home/
    [ $? -eq 0 ] && echo "旧的目录 $shengJi_home 删除成功！" &>>$logFile
    $dcp $hubIP $packages/shengJi_jetty $fxHome/ &>/dev/null
fi
chmod -R 755 $shengJi_home

#修改配置文件
if [ $dbIP ]; then
    iptest $dbIP

    echo "传入的IP是 dbIP:$dbIP" &>>$logFile
    setIP $shengJi_config $dbIP
fi

#启动服务
$shengJi_sh restart &>/dev/null
sleep 3
if ps -ef |grep -v grep |grep -q '/home/fx/shengJi_jetty'; then
    echo "启动升级服务成功" |tee -a $logFile
else
    echo "启动升级服务失败！" |tee -a $logFile
fi

#添加开机自启脚本到rc.local
chmod +x $rcFile
grep -q '升级服务' $rcFile
if [ $? -ne 0 ]; then
    echo -e "\n#升级服务\nsource /etc/profile\n$shengJi_sh restart" >>$rcFile
    echo "升级服务开机自启添加完成" &>>$logFile
fi

#服务器直接断电的情况下，jetty的pid文件不会被删除，start不启动jetty
#以前部署的 start 改成 restart
sed -i 's/jetty.sh start/jetty.sh restart/' $rcFile

