#!/bin/bash
# ntpSetIP.sh 设置ntp的同步IP

ntpServerIP=$1

fxHome=/home/fx
logFile=/mnt/install.log
scriptPath=/opt/installScript
toolsPath=$scriptPath/tools

ntpsh=$fxHome/ntpcron.sh
cronFile=/var/spool/cron/root

ipRep='((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)'

function iptest()
{
    [ -z "$*" ] && echo "ip不能为空" |tee -a $logFile && exit 8
    for ip in $*; do
        echo $ip |egrep -q "^$ipRep$"
        if [ $? -ne 0 ]; then
            echo "传入的($ip)IP格式不正确！！" |tee -a $logFile
            exit 8
        fi
    done
}


#日志
echo -e "\n#ntpSetIP\n`date`" &>>$logFile

if ! [ -f "$ntpsh" ]; then
    echo "创建ntpcron.sh" &>>$logFile
    cat >$ntpsh <<eof
#!/bin/bash
#echo "run ntp date start"
/usr/sbin/ntpdate -u 1.1.1.1 &>>/home/fx/ntp_cron.log
#echo "ntpdate run over"
eof
    chmod +x $ntpsh
fi

if [ -f $cronFile ]; then
    if ! grep -q 'ntpcron\.sh' $cronFile; then
        echo "插入ntp时间同步任务计划" &>>$logFile
        sed -i "1i\*/1  *   *   *   *   ${ntpsh}\n" $cronFile
    fi
else
    echo "创建ntp时间同步任务计划" &>>$logFile
    echo "*/1  *   *   *   *   $ntpsh" >>$cronFile
fi


if [ "$2" == 'app' ]; then
    #应用服务器则启动 ntpd服务
    echo "启动 ntpd服务" &>>$logFile
    rsync -a $toolsPath/ntp.conf /etc/

    systemctl start ntpd &>>$logFile
    systemctl enable ntpd &>>$logFile
    systemctl disable chronyd.service &>>$logFile
fi


#修改同步IP
iptest $ntpServerIP

if [ -f /home/fx/ntpcron.sh ]; then
    echo "同步IP修改成 $ntpServerIP" &>>$logFile
    sed -i "s/\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}/$ntpServerIP/" $ntpsh
else
    echo "没有/home/fx/ntpcron.sh 这个文件！" |tee -a $logFile
fi

