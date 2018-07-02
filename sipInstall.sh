#!/bin/bash

sipIP=$1
appIP=$2
mediaIP=$3
flag=$4


#日志
logFile=/mnt/install.log
if [ "$1" == "restart" ]; then
    echo -e "\n\n#restart-sip\n`date`" &>>$logFile
elif [ "$1" == "addMediaIP" ]; then
    echo -e "\n\n#addMediaIP-sip\n`date`" &>>$logFile
elif [ "$1" == "delMediaIP" ]; then
    echo -e "\n\n#delMediaIP-sip\n`date`" &>>$logFile
elif [ "$1" == "updateMediaIP" ]; then
    echo -e "\n\n#updateMediaIP-sip\n`date`" &>>$logFile
elif [ "$flag" == "updateIP" ]; then
    echo -e "\n\n#updateIP-sip\n`date`" &>>$logFile
elif [ -z $sipIP ] && [ -z $appIP ] && [ -z $mediaIP ]; then
    echo -e "\n\n#update-sip\n`date`" &>>$logFile
    #action='update'
elif [ $sipIP ] && [ $appIP ] && [ $mediaIP ]; then
    echo -e "\n\n#deploy-sip\n`date`" &>>$logFile
    #action='deploy'
fi

#运行脚本对服务器一些初始化以及导入一些通用变量和函数
toolsPath=/opt/installScript/tools
. $toolsPath/init.sh

#媒体用的变量
sipHome=$fxHome/smartsipserver
cfgFile=$sipHome/config/SmartSeeSipServer.config


##函数
#检测进程是否存在
function hasPid(){
    sipPid=`ps -ef |grep -v grep |grep '/SmartSeeSipServer$' |awk '{print$2}'`
    echo "进程号：sipPid=$sipPid" &>>$logFile
    if [ "$sipPid" == "" ]; then
        return 1
    else
        return 0
    fi
}
#停止信令
function stopSip(){
    killall -9 protect.sh &>>$logFile
    killall -9 Sprotect.sh &>>$logFile
    sleep 1
    if hasPid; then
        kill -9 $sipPid &>>$logFile
        sleep 3
        if hasPid; then
            sleep 2
            if hasPid; then
                kill -9 $sipPid &>>$logFile
                sleep 3
                if hasPid; then
                    echo '停止信令失败！' |tee -a $logFile
                    exit 3
                fi
            fi
        fi
        if [ "$sipIP" == 'stop' ]; then
            echo '停止信令成功' |tee -a $logFile
        else
            echo '停止信令成功' &>>$logFile
        fi
    else
        echo '信令进程不存在！' &>>$logFile
    fi
}
#启动信令
function startSip(){
    cd $sipHome
    ./Srun.sh &>/dev/null &
    sleep 2
    if ! hasPid; then
        sleep 2
        if ! hasPid; then
            echo '启动信令失败！' |tee -a $logFile
            return 1
        fi
    fi
    echo '启动信令成功' |tee -a $logFile

    ./Sprotect.sh &>/dev/null &
    return 0
}
#重启信令
function restartSip(){
    stopSip
    if startSip &>/dev/null; then
        echo '重启信令成功' |tee -a $logFile
    else
        echo '重启信令时启动失败！' |tee -a $logFile
    fi
}
#查配置文件中的媒体IP
function viewMediaIP(){
    echo `grep Transport1RelayServerIP $cfgFile |grep -Eo "$ipRep"`
}


case "$1" in
    restart)
        #重启信令
        restartSip
        exit 0
    ;;
    stop)
        #停止信令
        echo -e "\n\n#stop-sip\n`date`" &>>$logFile
        stopSip
        exit 0
    ;;
    viewMediaIP)
        echo -e "\n#viewMediaIP--`date`" &>>$logFile
        echo "信令配置文件中的媒体IP有：`viewMediaIP`" |tee -a $logFile
        grep Transport1RelayServerIP $cfgFile &>>$logFile
        exit 0
    ;;
    delMediaIP)
        #删除信令配置文件中若干个媒体IP
        if [ -f $cfgFile ]; then
            #获取全部位置参数，去除第一个(delMediaIP)
            mediaIPList=${@#$1}
            iptest $mediaIPList

            #删除前的检查信息
            viewMediaIP=`viewMediaIP`
            if [ -z "$viewMediaIP" ]; then
                echo "信令配置文件中已经没有媒体IP，不能进行删除！" |tee -a $logFile
                exit 1
            fi
            echo "==>删除前，信令配置文件中的媒体IP有：$viewMediaIP，要删除 $mediaIPList" &>>$logFile

            #遍历 mediaIPList，依次删除
            delFlag=false
            for mediaIP in $mediaIPList; do
                reg="^\s*$mediaIP\s+|\s+$mediaIP\s+|\s+$mediaIP\s*$|^\s*$mediaIP\s*$"
                if [[ $viewMediaIP =~ $reg ]]; then
                    sed -i "
                        /^Transport1RelayServerIP/ s/ $mediaIP:[0-9]*,/ /;
                        /^Transport1RelayServerIP/ s/,$mediaIP:[0-9]*$//;
                        /^Transport1RelayServerIP/ s/,$mediaIP:[0-9]*,/,/;
                        /^Transport1RelayServerIP/ s/ $mediaIP:[0-9]*$/ /
                    " $cfgFile
                    delFlag=true
                    if [ -z "$delMediaIP" ]; then
                        delMediaIP="$mediaIP"
                    else
                        delMediaIP+=" $mediaIP"
                    fi
                else
                   echo "信令配置文件中没有 $mediaIP 这个媒体IP" &>>$logFile 
                fi
            done

            viewMediaIP=`viewMediaIP`
            #如果没有删除则提前退出脚本
            if ! $delFlag; then
                echo "信令配置文件中没有要删除的媒体IP($mediaIPList)，存在的IP有：($viewMediaIP)" |tee -a $logFile
                exit 1
            fi
            if [ -z "$viewMediaIP" ]; then
                echo "删除后，信令配置文件中已经没有媒体IP，不能启动信令服务！" |tee -a $logFile
                exit 1
            fi

            #删除后的检查信息
            echo "删除 (${delMediaIP}) 成功，信令配置文件中还剩下的媒体IP有：$viewMediaIP" |tee -a $logFile
            grep Transport1RelayServerIP $cfgFile &>>$logFile

            restartSip
            exit 0
        else
            echo "没有找到信令服务配置文件！" |tee -a $logFile
            exit 1
        fi
    ;;
    updateMediaIP)
        #修改信令配置文件中某个媒体IP
        if [ -f $cfgFile ]; then
            oldMediaIP=$2
            newMediaIP=$3
            iptest $oldMediaIP $newMediaIP

            #修改前的检查信息
            viewMediaIP=`viewMediaIP`
            if [ -z "$viewMediaIP" ]; then
                echo "信令配置文件中已经没有媒体IP，不能进行修改！" |tee -a $logFile
                exit 1
            fi
            echo "==>修改前，信令配置文件中的媒体IP有：$viewMediaIP，要把 $oldMediaIP 修改成 $newMediaIP" &>>$logFile

            reg="^\s*$oldMediaIP\s+|\s+$oldMediaIP\s+|\s+$oldMediaIP\s*$|^\s*$oldMediaIP\s*$"
            if [[ $viewMediaIP =~ $reg ]]; then
                sed -i "/^Transport1RelayServerIP/ s/$oldMediaIP/$newMediaIP/" $cfgFile
            else
                echo "信令配置文件中不存在这个媒体IP($oldMediaIP)，不能修改！"
                exit 1
            fi

            echo -e "${oldMediaIP} 改成了 ${newMediaIP}\n修改后信令配置文件中的媒体IP有：`viewMediaIP`" |tee -a $logFile
            grep Transport1RelayServerIP $cfgFile &>>$logFile

            restartSip
            exit 0
        else
            echo "没有找到信令服务配置文件！" |tee -a $logFile
            exit 1
        fi
    ;;
    addMediaIP)
        #增加到信令配置文件中若干个媒体IP
        if [ -f $cfgFile ]; then
            mediaIPList=${@#$1}
            iptest $mediaIPList

            #添加前的检查信息
            viewMediaIP=`viewMediaIP`
            echo "==>添加前，信令配置文件中的媒体IP有：$viewMediaIP，要添加 $mediaIPList" &>>$logFile

            addFlag=false
            for mediaIP in $mediaIPList; do
                if grep -q "^Transport1RelayServerIP.*[= ,]$mediaIP:" $cfgFile; then
                    echo "$mediaIP 已经在在信令配置文件中！" &>>$logFile 
                else
                    sed -i "/^Transport1RelayServerIP/ s/$/,$mediaIP:5093/" $cfgFile
                    addFlag=true
                    if [ -z "$addMediaIP" ]; then
                        addMediaIP="$mediaIP"
                    else
                        addMediaIP+=" $mediaIP"
                    fi
                fi
            done

            viewMediaIP=`viewMediaIP`
            #如果没有添加则提前退出脚本
            if ! $addFlag; then
                echo "信令配置文件中已经存在媒体IP($mediaIPList)，所有存在的IP有：($viewMediaIP)" |tee -a $logFile
                exit 1
            fi

            echo "添加 (${addMediaIP}) 成功，添加后信令配置文件中的媒体IP有：$viewMediaIP" |tee -a $logFile
            grep Transport1RelayServerIP $cfgFile &>>$logFile

            restartSip
            exit 0
        else
            echo "没有找到信令服务配置文件！" |tee -a $logFile
            exit 1
        fi
    ;;
esac


#停止服务
stopSip
[ -f $sipHome/protect.sh ] && rm -f $sipHome/protect.sh
[ -f $sipHome/run.sh ] && rm -f $sipHome/run.sh
[ -f /etc/init.d/startsipserver ] && mv -v /etc/init.d/startsipserver /media &>>$logFile
[ -f /etc/init.d/mysql ] && mv -v /etc/init.d/mysql /media &>>$logFile


#从仓库下载安装包
if [ "$flag" == "updateIP" ]; then
    #改IP
    echo "开始修改信令配置文件中的IP" &>>$logFile
else
    if [ -f $cfgFile ] && [ -z $sipIP ] && [ -z $appIP ] && [ -z $mediaIP ]; then
        #升级
        echo "开始升级信令程序文件" &>>$logFile
        mv $cfgFile /opt/
        $dcp $hubIP $packages/smartsipserver $fxHome/ &>>$logFile
        rm -f $cfgFile
        mv /opt/SmartSeeSipServer.config $sipHome/config/
    elif [ $sipIP ] && [ $appIP ] && [ $mediaIP ]; then
        #安装
        echo "开始从 $hubIP 下载信令安装包" &>>$logFile
        [ -d $sipHome/ ] && rm -rvf $sipHome/ &>>$logFile
        $dcp $hubIP $packages/smartsipserver $fxHome/ &>>$logFile
    fi
    chmod -R 755 $sipHome
fi


#修改配置文件
if [ $sipIP ] && [ $appIP ] && [ $mediaIP ]; then
    iptest $sipIP $appIP

    echo "传入的IP是  sipIP:$sipIP appIP:$appIP mediaIP:$mediaIP" &>>$logFile
    sed -i "
    /^MCUServerIP/ s/= .*/= $sipIP/;
    /^LocalUserAddr/ s/@.*:/@$sipIP:/;
    /^IPAddress/ s/= .*/= $sipIP/;
    /^Transport1Interface/ s/= .*:/= $sipIP:/;
    /^Domains/ s/= .*/= $sipIP/;
    /^Transport1RecordRouteUri/ s/= .*:/= sip:$sipIP:/;
    /^Transport1LocalBindIP/ s/= .*:/= $sipIP:/;
    /^Transport1SipServerBindIP/ s/= .*/= $sipIP/;
    /^Domains/ s/= .*/= $sipIP/;
    /^RESTServerIP/ s/@.*:/@$appIP:/;
    /^Transport1RelayServerIP/ s/=.*:/= $mediaIP:/
" $cfgFile
fi

#修改编码
if [ "$sipIP" == "updateCode" ]; then
    code=$2
elif [ "$flag" == "updateCode" ]; then
    code=$5
fi

if [ "$code" ]; then
    if [ -f $cfgFile ]; then
        sed -i "/^RESTServerIP/ s/:.*@/:$code@/" $cfgFile
        echo "修改信令配置文件中的编码为：$code" |tee -a $logFile
    else
        echo "没有安装信令服务！" |tee -a $logFile
    fi
fi


#启动服务
startSip

#添加开机自启脚本到rc.local
chmod +x $rcFile
if ! grep -q "smartsipserver" $rcFile; then
    echo -e "\n#信令服务\ncd $sipHome\n./Sprotect.sh &" >>$rcFile
    echo "信令服务开机自启添加完成" &>>$logFile
fi

#旧版本的安装脚本是./protect.sh ，需要改成./Sprotect.sh
if grep -A2 "smartsipserver" $rcFile |grep -q './protect'; then
    sed -i '/smartsipserver/,/^#/ s/protect/Sprotect/' $rcFile
    echo "信令服务开机自启修改完成" &>>$logFile
fi

