#!/bin/bash

mediaIP=$1
sipIP=$2
flag=$3

#日志
logFile=/mnt/install.log
if [ "$1" == "restart" ]; then
    echo -e "\n\n#restart-media\n`date`" &>>$logFile
elif [ "$1" == "uninstall" ]; then
    echo -e "\n\n#uninstall-media\n`date`" &>>$logFile
elif [ "$flag" == "updateIP" ]; then
    echo -e "\n\n#updateIP-media\n`date`" &>>$logFile
elif [ -z $mediaIP ] && [ -z $sipIP ]; then
    echo -e "\n\n#update-media\n`date`" &>>$logFile
elif [ $mediaIP ] && [ $sipIP ]; then
    echo -e "\n\n#deploy-media\n`date`" &>>$logFile
fi


#运行脚本对服务器一些初始化
toolsPath=/opt/installScript/tools
. $toolsPath/init.sh

MEDIA_HOME=$fxHome/relayforlinux
cfgFile=$MEDIA_HOME/config/voipRelay.cfg

#停止服务函数
function stopMedia(){
    #killall -9 protect.sh
    killall -9 Mprotect.sh
    killall -9 MBRelayServer
    [ -f $MEDIA_HOME/protect.sh ] && rm -fv $MEDIA_HOME/protect.sh
    [ -f $MEDIA_HOME/run.sh ] && rm -fv $MEDIA_HOME/run.sh
    [ -f /etc/init.d/startrelayserver ] && mv -v /etc/init.d/startrelayserver /media
}

if [ "$1" == "restart" ]; then
    #重启
    if [ -f $cfgFile ]; then
        killall -9 MBRelayServer
        sleep 8
        ps -ef |grep -v grep |grep -q MBRelayServer
        [ $? -eq 0 ] && echo "重启媒体服务成功" |tee -a $logFile || echo "重启媒体服务失败！" |tee -a $logFile
        exit 0
    else
        echo "没有安装媒体服务！" |tee -a $logFile
        exit 1
    fi
elif [ "$1" == "uninstall" ]; then
    #卸载
    #停止服务
    stopMedia &>>$logFile 
    #删除安装目录
    rm -rf $MEDIA_HOME/
    #取消开机自启
    sed -i '/媒体服务/d; /relayforlinux/d; /Mprotect/d' $rcFile &>>$logFile 
    echo "卸载媒体服务器成功"
    exit 0
fi


#停止服务
stopMedia &>>$logFile 

#从仓库下载安装包
if [ "$flag" == "updateIP" ]; then
    #改IP：mediaInstall.sh $mediaIP $sipIP updateIP
    echo "开始修改媒体配置文件中的IP" &>>$logFile
else
    if [ -f $cfgFile ] && [ -z $mediaIP ] && [ -z $sipIP ]; then
        #升级：mediaInstall.sh
        echo "开始升级媒体程序文件" &>>$logFile
        mv $cfgFile /opt/
        $dcp $hubIP $packages/relayforlinux $fxHome/ &>>$logFile
        rm -f $cfgFile
        mv /opt/voipRelay.cfg $MEDIA_HOME
    elif [ $mediaIP ] && [ $sipIP ] && [ "$mediaIP" != "updateCode" ]; then
        #安装：mediaInstall.sh $mediaIP $sipIP
        echo "开始从 $hubIP 下载媒体安装包" &>>$logFile
        [ -d $MEDIA_HOME/ ] && rm -rvf $MEDIA_HOME/ &>>$logFile
        $dcp $hubIP $packages/relayforlinux $fxHome/ &>>$logFile
    fi
    chmod -R 755 $MEDIA_HOME
fi


#修改配置文件
if [ $mediaIP ] && [ $sipIP ] && [ "$mediaIP" != "updateCode" ]; then
    iptest $mediaIP $sipIP

    echo "传入的IP是 mediaIP:$mediaIP sipIP:$sipIP" &>>$logFile
    sed -i "
    /^localIP=/ s/localIP=.*/localIP=$mediaIP/;
    /^localBindIP=/ s/localBindIP=.*/localBindIP=$mediaIP/;
    /^fromAddr=/ s/fromAddr=.*/fromAddr=$sipIP/;
    /^registerIP=/ s/registerIP=.*/registerIP=$sipIP/
    " $cfgFile
fi

#修改编码
if [ "$1" == "updateCode" ]; then
    code=$2
elif [ "$flag" == "updateCode" ]; then
    code=$4
fi  

if [ "$code" ]; then
    if [ -f $cfgFile ]; then
        sed -i "/^username/ s/=.*/=$code/;
            /^authname/ s/=.*/=$code/;
            /^password/ s/=.*/=$code/;
            /^displayName/ s/=.*/=$code/;
            " $cfgFile
        echo "修改媒体配置文件中的编码为：$code" |tee -a $logFile
    else
        echo "没有安装媒体服务！" |tee -a $logFile
    fi
fi


#启动服务
cd $MEDIA_HOME
./Mprotect.sh &>/dev/null &

sleep 8
ps -ef |grep -v grep |grep -q MBRelayServer
if [ $? -eq 0 ]; then
    if [ "$code" ]; then
        echo "重启媒体服务成功" |tee -a $logFile
    else
        echo "启动媒体服务成功" |tee -a $logFile
    fi
else
    echo "启动媒体服务失败！" |tee -a $logFile
fi


#添加开机自启脚本到rc.local
chmod +x $rcFile
grep -q "relayforlinux" $rcFile
if [ $? -ne 0 ]; then
    echo -e "\n#媒体服务\ncd $MEDIA_HOME\n./Mprotect.sh &" >>$rcFile
    echo "媒体服务开机自启添加完成" &>>$logFile
fi

#旧版本的安装脚本是./protect.sh ，需要改成./Mprotect.sh
grep -A2 "relayforlinux" $rcFile |grep -q './protect'
if [ $? -eq 0 ]; then
    sed -i '/relayforlinux/,/^#/ s/protect/Mprotect/' $rcFile
fi

