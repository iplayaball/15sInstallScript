#!/bin/bash

#备份目录
fxHome=/home/fx
bkHome=$fxHome/backup
bkLog=/mnt/backup.log
restoreLog=/mnt/restore.log

script=/opt/installScript

#程序目录
appHome=$fxHome/wj_server
#appWar=$appHome/webapps/appserve.war

sipHome=$fxHome/smartsipserver
#sipWar=$sipHome/SmartSeeSipServer

mediaHome=$fxHome/relayforlinux
#mediaWar=$mediaHome/MBRelayServer

confHome=$fxHome/jiZhong_jetty
#confWar=$confHome/webapps/confManage.war

syncHome=$fxHome/datasync

upgradeHome=$fxHome/shengJi_jetty
#upgradeWar=$upgradeHome/webapps/oss.war

amqHome=$fxHome/amq

vtHome=$fxHome/vtserver
#vtWar=$vtHome/wujing/webapps/wj-vt.war
#mbWar=$vtHome/wujing/FxStreamServer/MBStreamServer

#程序备份目录
dbBak=$bkHome/db
appBak=$bkHome/app
sipBak=$bkHome/sip
mediaBak=$bkHome/media
confBak=$bkHome/conf
syncBak=$bkHome/sync
upgradeBak=$bkHome/upgrade
amqBak=$bkHome/amq
vtBak=$bkHome/vtserver

if ! [ "$1" == "restore" ]; then
    dbBakCurrent=$dbBak/$2
    appBakCurrent=$appBak/$2
    sipBakCurrent=$sipBak/$2
    mediaBakCurrent=$mediaBak/$2
    confBakCurrent=$confBak/$2
    syncBakCurrent=$syncBak/$2
    upgradeBakCurrent=$upgradeBak/$2
    amqBakCurrent=$amqBak/$2
    vtBakCurrent=$vtBak/$2
    case $1 in
        db)
            mkdir -p $dbBakCurrent/
            [ -f /usr/lib/libc.so.6 ] || ln -s /usr/lib64/libc.so.6 /usr/lib/libc.so.6
            /opt/ShenTong/bin/osrexp \
                -ufx_sys/123456 -hlocalhost -p2003 -dosrdb level=full \
                file=$dbBakCurrent/db.osr \
                log=$dbBakCurrent/bak.log \
                mode=entirety ignore=false \
                view=true sequence=true procedure=true constraint=true trigger=true index=true 1>/dev/null
            ;;
        app)
            mkdir -p $appBakCurrent/
            cd $appHome/
            rsync -a --exclude work --exclude run --exclude logs --exclude proxyua_log --exclude smartseeagent.log --exclude smartseeagent.log.old --exclude jetty.state $appHome $appBakCurrent/
            ;;
        sip)
            mkdir -p $sipBakCurrent/
            cd $sipHome/
            rsync -a --exclude logs --exclude 1.txt $sipHome $sipBakCurrent/
            ;;
        media)
            mkdir -p $mediaBakCurrent/
            cd $mediaHome/
            rsync -a --exclude logs --exclude 1.txt $mediaHome $mediaBakCurrent/
            ;;
        conf)
            mkdir -p $confBakCurrent/
            cd $confHome/
            rsync -a --exclude work --exclude run --exclude logs --exclude jetty.state $confHome $confBakCurrent/
            ;;
        sync)
            mkdir -p $syncBakCurrent/
            cd $syncHome/
            rsync -a --exclude log $syncHome $syncBakCurrent/
            ;;
        upgrade)
            mkdir -p $upgradeBakCurrent/
            cd $upgradeHome/
            rsync -a --exclude work --exclude run --exclude log --exclude jetty.state $upgradeHome $upgradeBakCurrent/
            ;;
        amq)
            mkdir -p $amqBakCurrent/
            rsync -a $amqHome $amqBakCurrent/
            ;;
        vtserver)
            mkdir -p $vtBakCurrent/
            cd $vtHome/
            rsync -a --exclude startjava.log \
                --exclude wujing/logs --exclude wujing/work --exclude wujing/start.log --exclude wujing/run \
                --exclude wujing/FxStreamServer/MBMediaEngine.log --exclude wujing/FxStreamServer/voipclient.log --exclude wujing/FxStreamServer/voipserver.cfg \
                $vtHome $vtBakCurrent/
            ;;
        *)
            echo "没有 $1 这个标识！"
    esac
else
    dbBakCurrent=$dbBak/$3
    appBakCurrent=$appBak/$3
    sipBakCurrent=$sipBak/$3
    mediaBakCurrent=$mediaBak/$3
    confBakCurrent=$confBak/$3
    syncBakCurrent=$syncBak/$3
    upgradeBakCurrent=$upgradeBak/$3
    amqBakCurrent=$amqBak/$3
    vtBakCurrent=$vtBak/$3

    . /etc/profile

    case $2 in
        db)
            /opt/ShenTong/bin/osrimp \
                -ufx_sys/123456 -hlocalhost -p2003 -dosrdb level=full \
                file=$dbBakCurrent/db.osr \
                log=$dbBakCurrent/restore.log \
                mode=entirety ignore=y \
                recreateschema=true view=true sequence=true procedure=true  constraint=true  deletetabledata=true trigger=true index=true 1>/dev/null
            ;;
        app)
            echo -e "\n`date`\napp" &>>$restoreLog
            rsync -av $appBakCurrent/wj_server $fxHome/ &>>$restoreLog
            rm -rf $appHome/work/*
            sh $script/appInstall.sh restart &>>$restoreLog
            ;;
        sip)
            echo -e "\n`date`\nsip" &>>$restoreLog
            rsync -av $sipBakCurrent/smartsipserver $fxHome/ &>>$restoreLog
            sh $script/sipInstall.sh restart &>>$restoreLog
            ;;
        media)
            echo -e "\n`date`\nmedia" &>>$restoreLog
            rsync -av $mediaBakCurrent/relayforlinux $fxHome/ &>>$restoreLog
            sh $script/mediaInstall.sh restart &>>$restoreLog
            ;;
        conf)
            echo -e "\n`date`\nconf" &>>$restoreLog
            rsync -av $confBakCurrent/jiZhong_jetty $fxHome/ &>>$restoreLog
            rm -rf $confHome/work/*
            $confHome/bin/jetty.sh restart &>>$restoreLog
            ;;
        sync)
            echo -e "\n`date`\nsync" &>>$restoreLog
            rsync -av $syncBakCurrent/datasync $fxHome/ &>>$restoreLog
            sh $script/datasyncInstall.sh restart &>>$restoreLog
            ;;
        upgrade)
            echo -e "\n`date`\nupgrade" &>>$restoreLog
            rsync -av $upgradeBakCurrent/shengJi_jetty $fxHome/ &>>$restoreLog
            rm -rf $upgradeHome/work/*
            $upgradeHome/bin/jetty.sh restart &>>$restoreLog
            ;;
        amq)
            echo -e "\n`date`\namq" &>>$restoreLog
            rsync -av $amqBakCurrent/amq $fxHome/ &>>$restoreLog
            $amqHome/bin/activemq restart &>>$restoreLog
            ;;
        vtserver)
            echo -e "\n`date`\nvtserver" &>>$restoreLog
            rsync -av $vtBakCurrent/vtserver $fxHome/ &>>$restoreLog
            killall -9 MBStreamServer &>>$restoreLog
            $vtHome/wujing/bin/jetty.sh stop &>>$restoreLog
            ;;
        *)
            echo "没有 $2 这个标识！"
    esac
fi
