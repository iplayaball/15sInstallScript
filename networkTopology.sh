#!/bin/bash
flag=$1
topologyFile=/usr/local/bin/getNetworkTopology

function startTopology(){
	/usr/local/bin/getNetworkTopology &
	sleep 1
	topologyPid=`ps -ef |grep -v grep |grep -w "\getNetworkTopology" |awk '{print$2}'`
	if [[ $topologyPid == "" ]]; then
		#statements
		echo -e '拓扑分发服务启动失败'
	elif [[ $topologyPid != "" ]]; then
		#statements
		echo -e '拓扑分发服务启动成功 ' $topologyPid
	fi
}

function stopTopology(){
	topologyPid=`ps -ef |grep -v grep |grep -w "\getNetworkTopology" |awk '{print$2}'`
	if [[ $topologyPid != "" ]]; then
		#statements
		kill -9 $topologyPid
	fi
}

function statusTopology(){
	topologyPid=`ps -ef |grep -v grep |grep -w "\getNetworkTopology" |awk '{print$2}'`
	if [[ $topologyPid == "" ]]; then
		#statements
		echo -e '\033[0;31;1m NetworkTopology.service is not running \033[0m'
	elif [[ $topologyPid != "" ]]; then
		#statements
		echo -e '\033[0;32;1m NetworkTopology.service is running pid= \033[0m' $topologyPid
	fi
}

if [[ $flag == "start" ]]; then
	#statements
	startTopology
	sleep 2
	statusTopology
elif [[ $flag == "stop" ]]; then
	#statements
	stopTopology
elif [[ $flag == "status" ]]; then
	#statements
	statusTopology
elif [[ $flag == "restart" ]]; then
	if [[ -f $topologyFile ]]; then
		#statements
		stopTopology
		sleep 2
		startTopology
	else
		echo "不存在拓扑分发软件,请部署拓扑分发软件"
	fi
	
elif [[ $flag == "" ]]; then
	#statements
	echo -e '\033[0;32;1m 请输入指令 pid= \033[0m'
fi