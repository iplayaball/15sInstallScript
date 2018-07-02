#!/bin/bash

function psPT() {
    ps -eo $1,args |grep -v grep |grep "$2" |awk -F'[/.]' '{print$1}' |head -1
}

#function psC() {
#    ps -eo args |grep -v grep |grep "$1"
#}

function json() {
	echo "\"$1\": {"
    echo -e "\t\"pid\":\"$2\","
    echo -e "\t\"time\":\"$3\""
	echo '}'
}

dbKey="oscar -o"
dbP=`psPT pid "$dbKey"`
dbT=`psPT lstart "$dbKey"`
#dbC=`psC "$dbKey"`

appKey="/home/fx/wj_server"
appP=`psPT pid "$appKey"`
appT=`psPT lstart "$appKey"`
#appC=`psC "$appKey"`

mediaKey="MBRelayServer"
mediaP=`psPT pid "$mediaKey"`
mediaT=`psPT lstart "$mediaKey"`
#mediaC=`psC "$mediaKey"`

sipKey="SmartSeeSipServer"
sipP=`psPT pid "$sipKey"`
sipT=`psPT lstart "$sipKey"`
#sipC=`psC "$sipKey"`

configKey="jiZhong_jetty"
configP=`psPT pid "$configKey"`
configT=`psPT lstart "$configKey"`
#configC=`psC "$configKey"`

datasyncKey="MainServer"
datasyncP=`psPT pid "$datasyncKey"`
datasyncT=`psPT lstart "$datasyncKey"`
#datasyncC=`psC "$datasyncKey"`

upgradeKey="shengJi_jetty"
upgradeP=`psPT pid "$upgradeKey"`
upgradeT=`psPT lstart "$upgradeKey"`
#upgradeC=`psC "$upgradeKey"`

amqKey="/home/fx/amq"
amqP=`psPT pid "$amqKey"`
amqT=`psPT lstart "$amqKey"`
#amqC=`psC "$amqKey"`


json db "$dbP" "$dbT"
json app "$appP" "$appT"
json media "$mediaP" "$mediaT"
json sip "$sipP" "$sipT"
json config "$configP" "$configT"
json datasync "$datasyncP" "$datasyncT"
json upgrade "$upgradeP" "$upgradeT"
json amq "$amqP" "$amqT"

