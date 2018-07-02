#!/bin/bash

dbIP=$1
dbSchema=NODE
flag=$3

#wj_server 应用程序
fxHome=/home/fx
wjHome=$fxHome/wj_server
wuJing_config=$wjHome/fx_digital/config/config.properties
wjSh=$wjHome/bin/jetty.sh

logFile=/mnt/install.log

#函数定义

#安装redis
function installRedis(){
    #安装redis
    [ -d /opt/redis/ ] && /opt/redis/bin/redis-cli shutdown
    [ -d /opt/redis/ ] && rm -rf /opt/redis/
    $dcp $hubIP $packages/redis/ /opt/ &>>$logFile
}


#检测进程是否存在
function hasPid(){
    appPid=`ps -ef |grep -v grep |grep -w "\-Djetty.home=$wjHome" |awk '{print$2}'`
    echo "进程号：appPid=("$appPid')' &>>$logFile
    if [ "$appPid" == "" ]; then
        return 1
    else
        return 0
    fi
}
#停止服务
function stopApp(){
    if hasPid; then
        if [ -f $wjSh ]; then
            $wjSh stop &>/dev/null
        else
            echo "应用服务的jetty.sh脚本不存在！开始kill掉进程" &>>$logFile
        fi
        sleep 1
        if hasPid; then
            kill $appPid &>>$logFile
            sleep 2
            if hasPid; then
                sleep 2
                if hasPid; then
                    kill -9 $appPid &>>$logFile
                    sleep 2
                    if hasPid; then
                        echo '停止应用失败！' |tee -a $logFile
                        exit 3
                    fi
                fi
            fi
        fi
        if [ "$dbIP" == 'stop' ]; then
            echo '停止应用成功' |tee -a $logFile
        else
            echo '停止应用成功' &>>$logFile
        fi
    else
        if [ "$dbIP" == 'stop' ]; then
            echo '应用服务没有在运行！' |tee -a $logFile
        else
            echo "应用进程不存在" &>>$logFile
        fi
    fi
}
#启动服务
function startApp(){
    $wjSh restart &>/dev/null
    if ! hasPid; then
        sleep 2
        if ! hasPid; then
            echo '启动应用失败！' |tee -a $logFile
            return 1
        fi
    fi
    echo '启动应用成功' |tee -a $logFile
    return 0
}
#重启
function restartApp(){
    stopApp
    if startApp &>/dev/null; then
        echo '重启应用成功' |tee -a $logFile
    else
        echo '重启应用时启动失败！' |tee -a $logFile
    fi
}


#日志
if [ "$1" == "restart" ]; then
    echo -e "\n#restart-app\n`date`" &>>$logFile
elif [ "$1" == "stop" ]; then
    echo -e "\n#stop-app\n`date`" &>>$logFile
elif [ "$1" == "start" ]; then
    echo -e "\n#start-app\n`date`" &>>$logFile
elif [ "$flag" == "updateIP" ]; then
    echo -e "\n\n#updateIP-app\n`date`" &>>$logFile
elif [ "$flag" == "update" ]; then
    echo -e "\n\n#update-app\n`date`" &>>$logFile
else
    echo -e "\n\n#deploy-app\n`date`" &>>$logFile
fi

source /etc/profile

#重启
if [ "$1" == "restart" ]; then
    restartApp
    exit 0
fi

#启动
if [ "$1" == "start" ]; then
    startApp
    exit 0
fi

#停止应用服务
stopApp
if [ "$1" == 'stop' ]; then
    exit 0
fi

#安装jdk
scriptPath=/opt/installScript
. $scriptPath/javaHome.sh

#ntp时间同步
rsync -a $toolsPath/ntp.conf /etc/

systemctl start ntpd &>>$logFile
systemctl enable ntpd &>>$logFile
systemctl disable chronyd.service &>>$logFile


#从仓库下载安装包
if [ $flag ];  then
    if [ $flag == "updateIP" ]; then
        #改IP
        echo "开始修改应用配置文件中的IP" &>>$logFile
    elif [ $flag == "update" ]; then
        #升级
        echo "开始升级应用程序的所有文件" &>>$logFile
        $dcp $hubIP $packages/libproxyua.so /usr/lib/ &>>$logFile
        $dcp $hubIP $packages/wj_server $fxHome/ &>/dev/null
        rm -rf $wjHome/work/*
        #安装redis
        installRedis
    fi
else
    #安装
    echo "开始从 $hubIP 下载应用安装包" &>>$logFile
    [ -d $wjHome/ ] && rm -rf $wjHome/
    [ $? -eq 0 ] && echo "旧的目录 $wjHome 删除成功"&>>$logFile
    $dcp $hubIP $packages/libproxyua.so /usr/lib/ &>>$logFile
    $dcp $hubIP $packages/wj_server $fxHome/ &>/dev/null
    #安装redis
    installRedis
fi
chmod -R 755 $wjHome


#修改配置文件
if [ $dbIP ]; then
    iptest $dbIP
    echo "传入的IP是 dbIP:$dbIP" &>>$logFile
    setSchema $wuJing_config $dbIP $dbSchema
fi

#启动应用服务
startApp

#添加开机自启脚本到rc.local
chmod +x $rcFile
grep -q '业务服务' $rcFile
if [ $? -ne 0 ]; then
    echo -e "\n#业务服务\nsource /etc/profile\n$wjSh restart" >>$rcFile
    echo "业务服务开机自启添加完成" &>>$logFile
fi

#服务器直接断电的情况下，jetty的pid文件不会被删除，start不启动jetty
#以前部署的 start 改成 restart
sed -i 's/jetty.sh start/jetty.sh restart/' $rcFile

