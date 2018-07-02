#!/bin/bash

scriptPath=/opt/installScript

fxHome=/home/fx
wjHome=$fxHome/wj_server
wjSh=$wjHome/bin/jetty.sh

datasync_home=$fxHome/datasync

sipHome=$fxHome/smartsipserver

jiZhong_home=$fxHome/jiZhong_jetty
jiZhong_sh=$jiZhong_home/bin/jetty.sh

shengJi_home=$fxHome/shengJi_jetty
shengJi_sh=$shengJi_home/bin/jetty.sh

source /etc/profile
 
function hasDbPid() {
    dbPid=`ps -ef |grep -v grep |grep 'oscar -o' |awk '{print$2}'`
    if [ "$dbPid" == "" ]; then
        return 1
    else
        echo -e "\n====>数据库进程号：dbPid=$dbPid"
        return 0
    fi  
}

function hasAppPid(){
    appPid=`ps -ef |grep -v grep |grep -w "\-Djetty.home=$wjHome" |awk '{print$2}'`
    if [ "$appPid" == "" ]; then
        return 1
    else
        echo -e "\n====>应用进程号：appPid=("$appPid')'
        return 0
    fi
}

function hasSyncPid(){
    syncPid=`ps -ef |grep -v grep |egrep -w 'MainServer|JettyServer' |awk '{print$2}'`
    if [ "$syncPid" == "" ]; then
        return 1
    else
        echo -e "\n====>同步进程号：syncPid=("$syncPid')'
        return 0
    fi
}

function hasSipPid(){
    sipPid=`ps -ef |grep -v grep |grep '/SmartSeeSipServer$' |awk '{print$2}'`
    if [ "$sipPid" == "" ]; then
        return 1
    else
        echo -e "\n====>信令进程号：sipPid=$sipPid"
        return 0
    fi
}

function hasMBPid(){
    MBPid=`ps -ef |grep -v grep |grep '/MBRelayServer$' |awk '{print$2}'`
    if [ "$MBPid" == "" ]; then
        return 1
    else
        echo -e "\n====>媒体进程号：MBPid=$MBPid"
        return 0
    fi
}
function hasConfPid(){
    confPid=`ps -ef |grep -v grep |grep -w "\-Djetty.home=$jiZhong_home" |awk '{print$2}'`
    if [ "$confPid" == "" ]; then
        return 1
    else
        echo -e "\n====>配置进程号：confPid=$confPid"
        return 0
    fi
}
function hasUpgPid(){
    upgPid=`ps -ef |grep -v grep |grep -w "\-Djetty.home=$shengJi_home" |awk '{print$2}'`
    if [ "$upgPid" == "" ]; then
        return 1
    else
        echo -e "\n====>升级进程号：upgPid=$upgPid"
        return 0
    fi
}

#数据库
if hasDbPid; then
    cd /etc/init.d/
    sh oscardb_OSRDBd stop

    
    sleep 1
    if hasDbPid; then
        echo "停止数据库失败！"
    else
        echo "停止数据库成功"
        rm -rf /opt/ShenTong
        rm -f /etc/init.d/oscardb_OSRDBd
    fi
fi

#应用服务
if hasAppPid; then
    $wjSh stop

    sleep 1
    if hasAppPid; then
        echo "停止应用失败！"
    else
        echo "停止应用成功"
        rm -rf $wjHome/
    fi
fi

#同步服务
if hasSyncPid; then
    sh $datasync_home/stop-datasync.sh
    sh $datasync_home/stop-syncweb.sh

    sleep 3
    if hasSyncPid; then
        echo "停止同步失败！"
    else
        echo "停止同步成功"
        rm -rf $datasync_home/
    fi
fi

#信令
if hasSipPid; then
    sh $scriptPath/sipInstall.sh stop

    sleep 6
    if hasSipPid; then
        echo "停止信令失败！"
    else
        echo "停止信令成功"
        rm -rf $sipHome
    fi
fi


#媒体
if hasMBPid; then
    sh $scriptPath/mediaInstall.sh uninstall

    sleep 6
    if hasMBPid; then
        echo "停止媒体失败！"
    else
        echo "停止媒体成功"
    fi
fi


#配置
if hasConfPid; then
    sh $jiZhong_sh stop

    sleep 1
    if hasConfPid; then
        echo "停止集中失败！"
    else
        echo "停止集中成功"
        rm -rf $jiZhong_home
    fi
fi

#升级
if hasUpgPid; then
    sh $shengJi_sh stop

    sleep 1
    if hasUpgPid; then
        echo "停止升级失败！"
    else
        echo "停止升级成功"
    fi
fi

