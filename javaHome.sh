#!/bin/bash

javaHome=/opt/jdk1.8.0_25

#定义设定配置文件IP的函数
function setIP()
{
    sed -i "/^url.jdbc/ s#//.*:#//$2:#" $1
}

#定义设定配置文件IP及模式名称的函数
function setSchema()
{
    setIP $1 $2
    sed -i "s/^sys.dbSchema.sql=.*/sys.dbSchema.sql=$3/" $1
}

#运行脚本对服务器一些初始化
toolsPath=/opt/installScript/tools
. $toolsPath/init.sh


if [ -d $javaHome ]; then
    chmod 755 -R $javaHome
else
    $dcp $hubIP $packages/jdk1.8.0_25.tar /opt/ &>>$logFile
    tar xf /opt/jdk1.8.0_25.tar -C /opt/
    chmod 755 -R $javaHome
fi

#添加java环境变量
grep -q "JAVA_HOME=/" /etc/profile
if [ $? -ne 0 ]; then
    cat >> /etc/profile << eof

##################################################################
#java 环境变量
export JAVA_HOME=$javaHome
export PATH=\$JAVA_HOME/bin:\$PATH
export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar
###################################################################
eof
fi

. /etc/profile

