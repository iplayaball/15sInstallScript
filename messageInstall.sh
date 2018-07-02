#!/bin/bash

logFile=/mnt/install.log
exec 1>>$logFile
thisDir=$(cd $(dirname $0) && pwd )

action=$1
localIP=$2
appIP=$3
syncIP=$4
sipIP=$5
relayIP=$6
vtIP=$7
username=$8
password=$9

#ipItem='localip appip datasync sip media vtip'
declare -A ipdict
ipdict=([localip]=$localIP [appip]=$appIP [datasync]=$syncIP [sip]=$sipIP [media]=$relayIP [vtip]=$vtIP)

#flag=$3

#服务相关变量
fxHome=/home/fx
messageHome=$fxHome/Message
messageCfg=$messageHome/config/config.xml


#函数定义
function sedf(){
    sed -i "/<$1>/,/<\/$1>/ c<$1>\n$2\n<\/$1>" $messageCfg
    sed -n "/<$1>/,/<\/$1>/p" $messageCfg
}

#日志
if [ $action == "install" ]; then
    echo -e "\n\n#install-message\n`date`"
elif [ $action == "update" ]; then
    echo -e "\n\n#update-message\n`date`"
fi
echo ***$0 $*

#运行脚本对服务器进行一些初始化
. $thisDir/tools/init.sh

#添加系统服务
cd $thisDir
chmod +x services/messagefx
rsync -av services/messagefx /etc/init.d/
chkconfig --add messagefx

#停止服务
service messagefx stop
if [ $? -ne 0 ]; then
    echo "网络拓扑配置程序停止失败！" >&2
    exit 3
fi

if [ $action == 'install' ]; then
    #下载安装包
    $dcp $hubIP $packages/Message $fxHome/
	chmod -R 755 $fxHome/Message

    #修改配置文件
    echo "------配置文件修改了的配置信息如下："
    for key in $(echo ${!ipdict[*]}); do
        #echo "$key : ${ipdict[$key]}"
        sedf $key ${ipdict[$key]}
    done
    sed -i "s/root/$username/" $messageCfg
    sed -i "s/123456/$password/" $messageCfg
    echo "--------------------------------"
elif [ $action == 'update' ]; then
    $dcp $hubIP $packages/Message/1409message.jar $messageHome/
fi

#启动服务
service messagefx start
service getNetworkService restart

