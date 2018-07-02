#!/bin/bash

/home/fx/wj_server/bin/jetty.sh stop
/home/fx/jiZhong_jetty/bin/jetty.sh stop
/home/fx/shengJi_jetty/bin/jetty.sh stop

/home/fx/datasync/stop-datasync.sh
/home/fx/datasync/stop-syncweb.sh


