#!/bin/bash

id=$1
syncIP=$2

[ -z $id ] && echo "没有传入id" && exit 3
[ -z $syncIP ] && echo "没有传入同步IP" && exit 3

logFile=/mnt/install.log
echo -e "\n\n`date`" &>>$logFile

#运行脚本对服务器一些初始化
toolsPath=/opt/installScript/tools
. $toolsPath/init.sh

ldapHome=/etc/openldap
ldapcfg=$ldapHome/slapd.conf
dataPath=/var/lib/ldap/001

#停止服务
systemctl stop slapd.service &>/dev/null
sleep 3
if ps -ef |grep -v grep |grep slapd; then
    echo "LDAP服务停止失败！" &>>$logFile
fi

#从仓库下载安装包
$dcp $hubIP $packages/openldap_install $fxHome/ &>>$logFile
chmod 755 -R $fxHome/openldap_install
sh $fxHome/openldap_install/ldap_install.sh &>>$logFile


#修改配置文件
rm -f $ldapcfg
cp $fxHome/openldap_install/ldap_cfg/slapd.conf $ldapHome

sed -i "s/^serverID.*/serverID $id/" $ldapcfg

syncIP=`echo $syncIP |sed 's/-/ /g'`

i=1
for ip in $syncIP; do
    cat >>$ldapcfg<< eof
syncrepl rid=$i
  provider=ldap://$ip
  bindmethod=simple  
  binddn="cn=replicator,ou=global,dc=fxdigital,dc=com"  
  credentials=openldap
  searchbase="ou=global,dc=fxdigital,dc=com"  
  schemachecking=off  
  type=refreshAndPersist  
  retry="60 +"  
mirrormode on

eof
    let i++
done

rm -rf $dataPath/*
cp -a /usr/share/openldap-servers/DB_CONFIG.example $dataPath/DB_CONFIG
cd $ldapHome
rm -rf slapd.d/*
slaptest -f slapd.conf -F slapd.d &>>$logFile
chown -R ldap:ldap slapd.d &>>$logFile
chown -R ldap:ldap $dataPath &>>$logFile

systemctl start slapd.service &>>$logFile
systemctl enable slapd.service &>>$logFile

sleep 5
ldapadd -x -D "cn=replicator,ou=global,dc=fxdigital,dc=com" -w openldap -f global.ldif &>>$logFile

if ps -ef |grep -v grep |grep -q slapd; then
    echo "LDAP服务启动成功" |tee -a $logFile
else
    echo "LDAP服务启动失败！" |tee -a $logFile
fi

