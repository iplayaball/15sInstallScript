#!/bin/bash

oldIP=$1
newIP=$2
gateway=$3

netcfgPath=/etc/sysconfig/network-scripts

function iptest()
{
    for ip in $*; do
        echo $ip |egrep -q "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"
        if [ $? -ne 0 ]; then
            echo "输入的 $ip IP格式不正确！！" |tee -a $logFile
            exit 8
        fi
    done
}

logFile=/mnt/install.log
echo -e "\n\n@@@@\n`date`" &>>$logFile

iptest $oldIP $newIP $gateway


#在网卡配置文件目录下找到包含 oldIP 的配置文件
ifcfg=`grep -r "^IPADDR=$oldIP$" $netcfgPath |cut -d: -f 1 |uniq`
[ -z "$ifcfg" ] && echo "不能找到 $oldIP 的网卡配置文件,修改失败！" |tee -a $logFile && exit 2

#用 oldIP 找到网卡的名称
netName=`ip a |grep -B2 $oldIP |grep 'state UP' |awk '{print$2}' |cut -d: -f1`
[ -z $netName ] && echo "不能找到 $oldIP 的网卡名称,修改失败！" |tee -a $logFile && exit 2
echo $netName |grep -q '\s' && echo "网卡名是$netName" &>>$logFile && exit 2

#找到的网卡配置文件可能一个也可能是多个，如果是两个再从中找包含此网卡名称的配置文件
if echo $ifcfg |grep -q '\s'; then
    ifcfg=`grep "^DEVICE=$netName" $ifcfg |cut -d: -f 1 |uniq`
    [ -z "$ifcfg" ] && echo "不能找到 $oldIP 的网卡配置文件,修改失败！" |tee -a $logFile && exit 2
    echo $ifcfg |grep -q '\s' && echo "网卡名是$ifcfg" &>>$logFile && exit 2
fi


#修改网卡配置文件
sed -i "
    /^#/! s/$oldIP/$newIP/;
    s/GATEWAY=.*/GATEWAY=$gateway/;
    s/BOOTPROTO=.*/BOOTPROTO=static/;
    s/ONBOOT=no/ONBOOT=yes/;
" $ifcfg

#网卡配置文件中没有配置GATEWAY项的情况下，添加GATEWAY项
if ! grep -q '^GATEWAY=' $ifcfg; then
    sed -i "/^IPADDR=/ a\GATEWAY=$gateway" $ifcfg
fi

echo "网卡配置文件：$ifcfg IP配置项由$oldIP 修改成$newIP 网关修改成$gateway" &>>$logFile

{ ifdown $netName; ifup $netName;} &>>$logFile

if [ $? -ne 0 ]; then
    /etc/init.d/network restart &>>$logFile
fi

