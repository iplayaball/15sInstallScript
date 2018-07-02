#!/bin/bash

localIP=$1
flag=$2

#wj_server 后台程序
fxHome=/home/fx
vtHome=$fxHome/vtserver
jettyHome=$vtHome/wujing
voipClient=$jettyHome/voipClient.cfg
cfgpr=$jettyHome/fx_digital/config/config.properties

strPath=$jettyHome/FxStreamServer
cfgxml=$strPath/config.xml
voipserver=$strPath/voipserver.cfg

logFile=/mnt/install.log
#日志
if [ "$flag" == "updateIP" ]; then
    echo -e "\n\n#updateIP-vtserver\n`date`" &>>$logFile
elif [ "$flag" == "update" ]; then
    echo -e "\n\n#update-vtserver\n`date`" &>>$logFile
else
    echo -e "\n\n#deploy-vtserver\n`date`" &>>$logFile
fi
echo ***$0 $* &>>$logFile

#函数定义
#检测进程是否存在
function hasMbPid(){
    mbPid=`ps -ef |grep -v grep |grep 'MBStreamServer\s\{1,\}start' |awk '{print$2}'`
    echo "进程号：mbPid=("$mbPid')' &>>$logFile
    if [ "$mbPid" == "" ]; then
        return 1
    else
        return 0
    fi
}

function hasVtPid(){
    vtPid=`ps -ef |grep -v grep |grep -w "\-Djetty.home=$jettyHome" |awk '{print$2}'`
    echo "进程号：vtPid=("$vtPid')' &>>$logFile
    if [ "$vtPid" == "" ]; then
        return 1
    else
        return 0
    fi
}

#停止服务
function stopMb(){
    if hasMbPid; then
        kill $mbPid &>>$logFile
        sleep 2
        if hasMbPid; then
            sleep 2
            if hasMbPid; then
                kill -9 $mbPid &>>$logFile
                sleep 2
                if hasMbPid; then
                    echo '停止代理程序失败！' |tee -a $logFile
                    exit 3
                fi
            fi
        fi
        if [ "$localIP" == 'stop' ]; then
            echo '停止代理程序成功' |tee -a $logFile
        else
            echo '停止代理程序成功' &>>$logFile
        fi
    else
        if [ "$dbIP" == 'stop' ]; then
            echo '代理程序没有在运行！' |tee -a $logFile
        else
            echo "代理程序进程不存在" &>>$logFile
        fi
    fi
}

function stopVt(){
    if hasVtPid; then
        if [ -f $jettyHome/bin/jetty.sh ]; then
            $jettyHome/bin/jetty.sh stop &>>$logFile
        else
            echo "vtserver的jetty.sh脚本不存在！开始kill掉进程" &>>$logFile
        fi
        sleep 1
        if hasVtPid; then
            kill $vtPid &>>$logFile
            sleep 2
            if hasVtPid; then
                sleep 2
                if hasVtPid; then
                    kill -9 $vtPid &>>$logFile
                    sleep 2
                    if hasVtPid; then
                        echo '停止vtserver失败！' |tee -a $logFile
                        exit 3
                    fi
                fi
            fi
        fi
        if [ "$localIP" == 'stop' ]; then
            echo '停止vtserver成功' |tee -a $logFile
        else
            echo '停止vtserver成功' &>>$logFile
        fi
    else
        if [ "$dbIP" == 'stop' ]; then
            echo 'vtserver没有在运行！' |tee -a $logFile
        else
            echo "vtserver进程不存在" &>>$logFile
        fi
    fi
}

create_rsyncCmdFile(){
    cat > $rsync_cmd_sh <<eof
cd $vtHome

#下面是一条rsync命令
rsync -e 'ssh -o stricthostkeychecking=no' -av \\
	--exclude wujing/database \\
		--exclude wujing/fx_digital/config/config.properties \\
		--exclude startjava.log --exclude MBStreamServer.txt --exclude vtserverJetty.txt \\
		--exclude wujing/logs --exclude wujing/work --exclude wujing/start.log \\
		--exclude wujing/run --exclude wujing/jetty.state \\
	--exclude wujing/FxStreamServer/SmartSeeEngine.log \\
		--exclude wujing/FxStreamServer/SmartSeeEngineMain.log \\
		--exclude wujing/FxStreamServer/SmartSeeEngineSub_1.log \\
		--exclude wujing/FxStreamServer/SmartSeeEngineSub_2.log \\
		--exclude wujing/FxStreamServer/voipclient.log \\
		--exclude wujing/FxStreamServer/voipclient.log.old \\
$hubIP:$packages/vtserver $fxHome/
eof
}

#auto_rsync () {
#    expect -c "set timeout -1;
#                spawn rsync -e 'ssh -o stricthostkeychecking=no' -av $hubIP:$packages/vtserver $fxHome/;
#                expect {
#                    *assword:* {send -- 123456\r;
#                                 expect {
#                                    *denied* {exit 1;}
#                                    eof
#                                 }
#                    }
#                    eof         {exit 1;}
#                }
#                "
#    return $?
#}

#启动服务
#function startMb(){
#    rm -fv /home/fx/vtserver/wujing/run/jetty.pid &>$vtHome/startjava.log
#    $strPath/start.sh &>>$vtHome/startjava.log
#    if ! hasMbPid; then
#        sleep 2
#        if ! hasMbPid; then
#            echo '启动代理程序失败！' |tee -a $logFile
#            exit 1
#        fi
#    fi
#    echo '启动代理程序成功' &>>$logFile
#    return 0
#}
#
#function startVt(){
#    $jettyHome/bin/jetty.sh start &>>$vtHome/startjava.log
#    if ! hasVtPid; then
#        sleep 2
#        if ! hasVtPid; then
#            echo '启动vtserver程序失败！' |tee -a $logFile
#            exit 1
#        fi
#    fi
#    echo '启动vtserver程序成功' |tee -a $logFile
#    return 0
#}

#停止vtserver
source /etc/profile
killall -9 protect.sh &>>$logFile

stopVt

stopMb

#重启
#

#安装jdk
scriptPath=/opt/installScript
. $scriptPath/javaHome.sh


#从仓库下载安装包
if [ "$flag" ];  then
    if [ "$flag" == "updateIP" ]; then
        #改IP
        echo "开始修改vt配置文件中的IP" &>>$logFile
    elif [ "$flag" == "update" ]; then
        #升级
        ##升级前将虚拟终端代理的配置文件voipserver.cfg的registerIP参数读取出来当做 natIP
        natIP=`awk -F'=' '{if($1~/^registerIP/) print$2}' $voipserver`
        echo "读取natIP为 $natIP" &>>$logFile

        echo "开始升级vt程序的所有文件" &>>$logFile
        #rm -rfv /mnt/database &>>$logFile
        #mv -v $jettyHome/database /mnt/ &>>$logFile
        #[ $? -ne 0 ] && echo "移动database失败！" && exit 1
        #$rsync_sh $hubIP $packages/vtserver $fxHome/ &>>$logFile
        #rm -rvf $jettyHome/database &>>$logFile
        #mv -v /mnt/database $jettyHome/ &>>$logFile
        create_rsyncCmdFile

        echo '=======执行的rsync命令=======' &>>$logFile
        cat $rsync_cmd_sh &>>$logFile
        echo '=============================' &>>$logFile

        auto_rsync &>>$logFile

        rm -rf $jettyHome/work/*
    fi
else
    #安装
    echo "如果存在vt程序目录则删除，并下载新的安装程序文件" &>>$logFile
    [ -d $vtHome/ ] && rm -rf $vtHome/ &>>$logFile
    $dcp $hubIP $packages/vtserver $fxHome/ &>/dev/null
fi
chmod -R 755 $vtHome


#修改配置文件
if [ $localIP ]; then
    iptest $localIP

	#安装时没有传入natIP，所以让natIP等于本地系统IP
	#升级时的natIP是上面读出来的
	if [ -z "$natIP" ]; then
		natIP=$localIP
	fi

    echo -e "\n" &>>$logFile

    #vt的配置文件
    ##修改第一个配置文件 ----->暂时不用修改
    #sed -i "/^host=/ s/=.*/=$localIP/" $cfgpr
    ##修改后的查看
    #echo $cfgpr &>>$logFile
    #grep  "^host=" $cfgpr &>>$logFile

    ##修改第二个配置文件
	##本地系统IP
    sed -i "
		/^localBindIP=/ s/=.*/=$localIP/;
    " $voipClient
	##本节点natIP
    sed -i "
		/^fromAddr=/ s/=.*/=$natIP/;
		/^localIP=/ s/=.*/=$natIP/;
		/^registerIP=/ s/=.*/=$natIP/;
    " $voipClient
    #修改后的查看
    echo "vt的配置文件修改结果如下：" &>>$logFile
    echo $voipClient &>>$logFile
    egrep "^(fromAddr=|localIP=|localBindIP=|registerIP=)" $voipClient &>>$logFile

    #vt代理的配置文件
    ##修改第一个配置文件
	##本地系统IP
    sed -i "
		/^localBindIP=/ s/=.*/=$localIP/;
		/^restServerIp=/ s/=.*/=$localIP/;
    " $voipserver
	##本节点natIP
    sed -i "
		/^fromAddr=/ s/=.*/=$natIP/;
		/^localIP=/ s/=.*/=$natIP/;
		/^registerIP=/ s/=.*/=$natIP/;
    " $voipserver
    ##修改后的查看
    echo "vt代理的配置文件修改结果如下：" &>>$logFile
    echo $voipserver &>>$logFile
    egrep "^(fromAddr=|localIP=|localBindIP=|registerIP=|restServerIp=)" $voipserver &>>$logFile
    
    ##修改第二个配置文件
    sed -i "/<RestServerAddress>http:/ s#//.*:#//$localIP:#" $cfgxml
    ##修改后的查看
    echo $cfgxml &>>$logFile
    grep "<RestServerAddress>http:" $cfgxml &>>$logFile
    echo -e '\n' &>>$logFile
fi


#启动vt服务
$vtHome/int/startjava &> $vtHome/startjava.log

if ! hasMbPid; then
    sleep 4
    if ! hasMbPid; then
        echo '启动代理程序失败！' |tee -a $logFile
        exit 1
    fi
fi
echo '启动代理程序成功' &>>$logFile

$jettyHome/bin/jetty.sh start &>>$vtHome/startjava.log
if ! hasVtPid; then
    sleep 2
    if ! hasVtPid; then
        echo '启动vtserver程序失败！' |tee -a $logFile
        exit 1
    fi
fi
echo '启动vtserver程序成功' |tee -a $logFile

#添加开机自启脚本到rc.local
chmod +x $rcFile
if ! grep -q "$vtHome/int/startjava" $rcFile; then
    echo -e "\n#vtserver服务\nsource /etc/profile\n$vtHome/int/startjava &> $vtHome/startjava.log" >>$rcFile
    echo "vtserver服务开机自启添加完成" |tee -a $logFile
fi

