#!/bin/bash

LOCAL_IP=$1
DB_IP=$2
DB_SCHEMA=NODE
flag=$4


#日志
logFile=/mnt/install.log
if [ "$flag" == "updateIP" ]; then
    echo -e "\n\n#updateIP-sync\n`date`" &>>$logFile
elif [ "$flag" == "update" ]; then
    echo -e "\n\n#update-sync\n`date`" &>>$logFile
elif [ "$1" == "restart" ]; then
    echo -e "\n#restart-sync\n`date`" &>>$logFile
elif [ "$1" == "stop" ]; then
    echo -e "\n#stop-sync\n`date`" &>>$logFile
elif [ "$1" == "start" ]; then
    echo -e "\n#start-sync\n`date`" &>>$logFile
else
    echo -e "\n\n#deploy-sync\n`date`" &>>$logFile
fi


fxHome=/home/fx
datasync_home=$fxHome/datasync
datasync_config1=$datasync_home/config/tomcat_jdbc.properties
datasync_config2=$datasync_home/web/syncmanage/WEB-INF/classes/config/cascade.properties
datasync_spring=$datasync_home/config/spring-rmi.xml

#停止函数
function stopSync()
{
    sh $datasync_home/stop-datasync.sh &>>$logFile
    sh $datasync_home/stop-syncweb.sh &>>$logFile
    sleep 3
    if ps -ef |grep -v grep |egrep -q 'MainServer|JettyServer'; then
        echo "同步服务停止失败！" |tee -a $logFile
        exit 3
    fi
}

#启动函数
function startSync()
{
    sh $datasync_home/start-syncweb.sh &>/dev/null
    sleep 5
    if ! ps -ef |grep -q JettyServer; then
        echo "syncweb 服务启动失败！" |tee -a $logFile
        return 1
    fi
    if ! netstat -anput |grep -wq 6006 &>>$logFile; then
        echo "启动后6006端口不能访问！" |tee -a $logFile
        return 1
    fi
    sh $datasync_home/start-datasync.sh &>/dev/null
    sleep 2
    if ps -ef |grep -q MainServer; then
        echo "同步服务启动成功" |tee -a $logFile
        return 0
    else
        echo "datasync 服务启动失败！" |tee -a $logFile
        return 1
    fi
}

#重启
if [ "$1" == "restart" ]; then
        source /etc/profile
        stopSync
        startSync &>>$logFile
        if [ $? -eq 0 ]; then
            echo "同步服务重启成功" |tee -a $logFile
        else
            echo "同步服务重启失败！" |tee -a $logFile
        fi
        exit 0
elif [ "$1" == "start" ]; then
        source /etc/profile

        startSync &>>$logFile
        if [ $? -eq 0 ]; then
            echo "同步服务启动成功" |tee -a $logFile
        else
            echo "同步服务启动失败！" |tee -a $logFile
        fi
        exit 0
elif [ "$1" == "stop" ]; then
        source /etc/profile

        stopSync &>>$logFile
        echo "同步服务停止成功" |tee -a $logFile

        exit 0
fi


#安装jdk
scriptPath=/opt/installScript
. $scriptPath/javaHome.sh


#停止服务
if [ -d $datasync_home ]; then
    stopSync
fi


#从仓库下载安装包
if [ "$flag" == "updateIP" ]; then
    #改IP
    echo "开始修改同步配置文件中的IP" &>>$logFile
elif [ "$flag" == "update" ]; then
    #升级
    echo "开始升级同步程序的所有文件" &>>$logFile
    $dcp $hubIP $packages/datasync.tar.gz $fxHome/ &>>$logFile
    tar xf $fxHome/datasync.tar.gz -C $fxHome/ &>>$logFile
else
    #安装
    [ -d $datasync_home/ ] && rm -rf $datasync_home/
    [ $? -eq 0 ] && echo "旧的目录 $datasync_home 删除成功" &>>$logFile
    echo "开始从 $hubIP 下载同步的安装包" &>>$logFile
    $dcp $hubIP $packages/datasync.tar.gz $fxHome/ &>>$logFile
    tar xf $fxHome/datasync.tar.gz -C $fxHome/ &>>$logFile
fi
chmod -R 755 $datasync_home


#修改配置文件
if [ $LOCAL_IP ] && [ $DB_IP ]; then
    iptest $LOCAL_IP $DB_IP

    echo "传入的IP是 LOCAL_IP:$LOCAL_IP DB_IP:$DB_IP" &>>$logFile
    sed -i "/serverHost/ s/value=\".*\"/value=\"$LOCAL_IP\"/" $datasync_spring

    setSchema $datasync_config1 $DB_IP $DB_SCHEMA
    setSchema $datasync_config2 $DB_IP $DB_SCHEMA
fi


#启动服务
startSync

#添加开机自启脚本到rc.local
chmod +x $rcFile
grep -q '同步服务' $rcFile
if [ $? -ne 0 ]; then
    echo -e "\n#同步服务\nsource /etc/profile\n$datasync_home/start-syncweb.sh\nsleep 5\n$datasync_home/start-datasync.sh" >>$rcFile
    echo "同步服务开机自启添加完成" &>>$logFile
else
    if ! sed -n '/start-syncweb/,/start-datasync/p' $rcFile |grep -q 'sleep'; then
        sed -i '/start-syncweb/ a\sleep 5' $rcFile
        echo "同步服务开机自启添加sleep完成" &>>$logFile
    fi
fi

