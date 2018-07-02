#!/bin/bash

#全网监控不使用快速部署安装时使用

logFile=monitorDmInstall.log
exec 1>>$logFile
thisDir=$(cd $(dirname $0) && pwd )

fxHome=/home/fx
dm_install_path=$thisDir/dm_install
init_sql_path=$thisDir/dm_init_sql
dmHome=/opt/dmdbms
dbPort=5266
dbName=FXDB
dbUser=FX_SYS
dbPwd=123456789


#日志开始
echo -e "\n\n#deploy-monitorDm\n`date`"

#检测进程是否存在
dbKey="dmserver.*data/$dbName/dm.ini"
function hasPid(){
    dbPid=`ps -ef |grep -v grep |grep "$dbKey" |awk '{print$2}'`
    echo "进程号：dbPid=$dbPid"
    if [ "$dbPid" == "" ]; then
        return 1
    else
        return 0
    fi
}

#停止函数
function dbStop() {
    if ! hasPid; then
        echo "数据库之前没有运行"
        return 0
    fi

    if hasPid; then
        systemctl stop DmService$dbName.service
        sleep 2
        if hasPid; then
            kill $dbPid
            sleep 2
            if hasPid; then
                kill -9 $dbPid
                sleep 3
                if hasPid; then
                    echo '停止数据库失败！'
                    exit 3
                fi
            fi
        fi
    fi
    echo '停止数据库成功'
}

#启动函数
function dbStart() {
    #cd /home/dmdba/dmdbms/bin/
    #./DmServiceDMSERVER start
    systemctl start DmService$dbName.service

    sleep 2
    if hasPid; then
        echo "数据库启动成功" >&2
    else
        echo "数据库启动失败！" >&2
        exit 1
    fi
}


##########################################################################################################################
#为数据库创建需要的系统账户
if ! id dmdba &>/dev/null; then
    echo "创建系统组和用户：dinstall dmdba"
    groupadd dinstall &>>$logFile
    useradd -g dinstall -m -d /home/dmdba -s /bin/bash dmdba &>>$logFile
fi

#先尝试停止进程
dbStop

#安装
if ! [ -d $dmHome ]; then
    cd $dm_install_path/
    sed -i "/KEY/ s#>.*<#>$dm_install_path/dm.key<#" dmcfg.xml
    chmod +x ./DMInstall.bin
    ./DMInstall.bin -q $dm_install_path/dmcfg.xml
fi

#创建实例
createInstanceFlag=false
if ! [ -d $dmHome/data/$dbName ]; then
    su - dmdba -c  "$dmHome/bin/dminit PATH=$dmHome/data DB_NAME=$dbName CASE_SENSITIVE=N INSTANCE_NAME=$dbName PAGE_SIZE=32 UNICODE_FLAG=0 PORT_NUM=$dbPort" &>>$logFile
    chown -R dmdba:dinstall $dmHome/data &>>$logFile
    $dmHome/script/root/root_db_service_installer.sh -f $dmHome/data/$dbName/dm.ini  -n $dbName -m open

    createInstanceFlag=true
fi

#启动FXDB实例
dbStart
if $createInstanceFlag; then
    echo '实例是新创建的，需要等待50秒'
    sleep 50
fi
sleep 5

#创建用户和模式
cd $dmHome/bin/
./disql SYSDBA/SYSDBA:$dbPort \`$init_sql_path/createUser.sql
#./disql $dbUser/$dbPwd:$dbPort \`$init_sql_path/createSchema.sql

#导入飞讯初始化数据
echo '开始导入初始化数据'
#./disql $dbUser/$dbPwd:$dbPort \`$init_sql_path/node.sql &>/mnt/init_node.log
#./disql $dbUser/$dbPwd:$dbPort \`$init_sql_path/platpub.sql &>/mnt/init_platpub.log
echo '导入初始化数据结束' >&2

