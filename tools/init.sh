#!/bin/bash

fxHome=/home/fx
scriptPath=/opt/installScript
toolsPath=$scriptPath/tools
dcp=$toolsPath/dcp.sh
rsync_sh=$toolsPath/rsync.sh
rsync_cmd_sh=$toolsPath/rsync_cmd.sh
packages=/home/fx/1409_installServer/packages
logFile=/mnt/install.log
rcFile=/etc/rc.d/rc.local
ntpsh=/home/fx/ntpcron.sh
cronFile=/var/spool/cron/root

#hosts=/etc/hosts
hubIP=192.168.4.189

ipRep='((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)'

function iptest()
{
    for ip in $*; do
        echo $ip |egrep -q "^$ipRep$"
        if [ $? -ne 0 ]; then
            echo "传入的($ip)IP格式不正确！！"
            exit 8
        fi
    done
}

auto_rsync () {
    expect -c "set timeout -1;
                spawn sh $rsync_cmd_sh;
                expect {
                    *assword:* {send -- 123456\r;
                                 expect {
                                    *denied* {exit 1;}
                                    eof
                                 }
                    }
                    eof         {exit 1;}
                }
                "
    return $?
}


systemctl stop firewalld.service &>>$logFile
systemctl disable firewalld.service &>>$logFile


#if grep -v '^#' /etc/hosts |grep -q 'fx\.hub\.com'; then
#    sed -i "s/^[^#].*\(fx\.hub\.com\)/$hubIP  \1/" $hosts
#else
#    echo "$hubIP  fx.hub.com" >>/etc/hosts
#fi
if ! [ -f "$ntpsh" ]; then
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
        sed -i "1i\*/1  *   *   *   *   $ntpsh" $cronFile
    fi
else
    echo "*/1  *   *   *   *   $ntpsh" >>$cronFile
fi


expect -v &>/dev/null
if [ $? -ne 0 ]; then
    rpm -ivh $toolsPath/tcl-8.5.13-8.el7.x86_64.rpm &>/dev/null
    rpm -ivh $toolsPath/expect-5.45-14.el7_1.x86_64.rpm &>/dev/null
    expect -v &>/dev/null
    if [ $? -ne 0 ]; then
        echo "expect install failed"
        exit 3
    fi
fi

chmod +x $dcp

egrep -q "\#\!/bin/bash|\#\!/bin/sh" $rcFile
if [ $? -ne 0 ];then
    echo -e "不存在解释器,重新添加"&>>$logFile
    sed -i '1i#!/bin/bash' $rcFile
fi

