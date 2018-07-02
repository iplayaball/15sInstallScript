#!/bin/bash

#放在目录 wj_server/bin/ 下。
#给应用开机自启用

logFile=/mnt/startApp_waitDm.log

while true; do
	if ! netstat -anput |grep -qw 5266; then
		echo "`date`--->达梦数据库的端口5266还没在监听,等待5秒！" >>$logFile
		sleep 5
	else
		echo "`date`--->达梦数据库的端口5266已经在监听" >>$logFile
		break
	fi
done

