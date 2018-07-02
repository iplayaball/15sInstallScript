#!/bin/bash

case $1 in
    shentong)
        ps -ef |grep -v grep |grep 'oscar -o'
        ;;
    appserver)
        ps -ef |grep -v grep |grep '/home/fx/wj_server'
        ;;
    media)
        ps -ef |grep -v grep |grep MBRelayServer
        ;;
    sip)
        ps -ef |grep -v grep |grep SmartSeeSipServer
        ;;
    con)
        ps -ef |grep -v grep |grep jiZhong_jetty
        ;;
    upgrade)
        ps -ef |grep -v grep |grep shengJi_jetty
        ;;
    datasync)
        ps -ef |grep -v grep |egrep 'JettyServer|MainServer'
        ;;
    amq)
        ps -ef |grep -v grep |grep '/home/fx/amq'
        ;;
    *)
        echo "没有 $1 服务"
        ;;
esac

