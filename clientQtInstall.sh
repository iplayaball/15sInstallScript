#!/bin/bash

flag=$1

#日志
logFile=/mnt/install.log

#删除程序文件
function delProgram(){
	if [[ -d /opt/LocalizationTerminal ]]; then
		#statements
		rm -rf /opt/LocalizationTerminal
		if [[ -d /opt/LocalizationTerminal ]]; then
			#statements
			echo "删除程序失败" &>>$logFile
		fi
	fi
}
#删除应用库
function delLibrary(){
	if [[ -d /opt/Qt5.6.3 ]]; then
		#statements
		rm -rf /opt/Qt5.6.3
		if [[ -d /opt/Qt5.6.3 ]]; then
			#statements
			echo "删除应用库失败" &>>$logFile
		fi	
	fi
}
#删除启动文件
function delSetup(){
	if [[ -f /root/桌面/LocalizationTerminal.desktop ]]; then
		#statements
		rm -f /root/桌面/LocalizationTerminal.desktop
		if [[ -f /root/桌面/LocalizationTerminal.desktop ]]; then
			#statements
			echo "删除启动文件失败" &>>$logFile
		fi
	fi
}

#下载程序文件
function scpProgram(){
	$dcp $hubIP $packages/clientQt/LocalizationTerminal.tar.gz /opt/ &>>$logFile
	tar xf /opt/LocalizationTerminal.tar.gz -C /opt/ &>/dev/null
	rm -f /opt/LocalizationTerminal.tar.gz 
	chmod 777 -R /opt/LocalizationTerminal/
	echo "`date`===>下载客户端执行文件结束" &>>$logFile
}
#下载应用库
function scpLibrary(){
	$dcp $hubIP $packages/clientQt/Qt5.6.3.tar.gz /opt/ &>>$logFile
	tar xf /opt/Qt5.6.3.tar.gz -C /opt/ &>/dev/null
	rm -f /opt/Qt5.6.3.tar.gz
	chmod 777 -R /opt/Qt5.6.3
	echo "`date`===>下载应用库结束" &>>$logFile
}
#下载启动文件
function scpSetup(){
	$dcp $hubIP $packages/clientQt/LocalizationTerminal.desktop /root/桌面 &>>$logFile
	chmod 777 /root/桌面/LocalizationTerminal.desktop
	echo "`date`===>下载启动文件结束" &>>$logFile
}

#运行脚本对服务器一些初始化
toolsPath=/opt/installScript/tools
. $toolsPath/init.sh

if [[ $flag == 'install' ]]; then
	#statements
	echo -e "\n\n#deploy-client\n`date`" &>>$logFile
	scpProgram
	scpLibrary
	scpSetup
	echo '部署客户端完毕'
elif [[ $flag == 'uninstall' ]]; then
	echo -e "\n\n#uninstall-client\n`date`" &>>$logFile
	#statements
	delProgram
	delLibrary
	delSetup
	echo '删除客户端文件完成'
fi

