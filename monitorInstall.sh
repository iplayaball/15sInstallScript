#!/bin/bash

flag=$1
fxHome=/home/fx
monitor=$fxHome/monitor_jetty
#日志
logFile=/mnt/install.log

#运行脚本对服务器一些初始化
toolsPath=/opt/installScript/tools
. $toolsPath/init.sh

function hashPid(){
	monitorPid=`ps -ef |grep -v grep |grep -w "\-Djetty.home=$monitor" |awk '{print$2}'`
    echo "进程号：appPid=("$monitorPid')' &>>$logFile
    if [ "$monitorPid" == "" ]; then
    	echo "启动失败" &>>$logFile
        return 1
    else
    	echo "启动成功" &>>$logFile
        return 0
    fi
}

function uninstallMonitor(){
	echo "卸载全网监控服务" &>>$logFile
	sh $monitor/bin/jetty.sh stop &>>$logFile
	rm -rf $monitor
}
function installMonitor(){
	echo "安装全网监控服务" &>>$logFile
	#statements
	$dcp $hubIP $packages/topo_install $fxHome &>>$logFile
	cd $fxHome/topo_install
	sh deployTopo.sh &>>$logFile
	rm -rf $fxHome/topo_install
	if [[ hashPid ]]; then
		#statements
		echo "部署全网监控结束,启动成功"
	else
		echo "部署全网监控结束,启动失败"
	fi
}

if [[ $flag == 'install' ]]; then
	installMonitor	
elif [[ $flag == 'uninstall' ]]; then
	#statements
	uninstallMonitor
fi

