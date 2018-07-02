#!/usr/bin/env python
# coding:utf-8

import commands
import re
import json
import sys

dbKey = "dmserver"

fxHome = '/home/fx'

appHome = fxHome + '/wj_server'
appKey = '\-Djetty.home=' + appHome

mediaKey = "MBRelayServer$"
mPkey = 'Mprotect.sh'

sipKey = "/SmartSeeSipServer$"
sPkey = 'Sprotect.sh'

syncJettyKey = 'fx.cascade.server.JettyServer'
syncMainKey = 'fx.cascade.server.MainServer'

confHome = fxHome + '/jiZhong_jetty'
confKey = '\-Djetty.home=' + confHome

upgradeHome = fxHome + '/shengJi_jetty'
upgradeKey = '\-Djetty.home=' + upgradeHome

vtHome = fxHome + '/vtserver/wujing'
vtKey = '\-Djetty.home=' + vtHome

#mbKey = 'MBStreamServer\s{1,}start'
vtPkey = '/protect.sh'

streamKey = '(MB)?Stream(Sub)?Server'

ctime = commands.getoutput('date')
servers = [{"currentTime": ctime}]


def ps(key, name):
    pscmd = "ps -eo ppid,pid,lstart,etime,args |grep -v grep |egrep '%s'" % key
    psout = commands.getoutput(pscmd).splitlines()

    server = {name: []}

    for line in psout:
        allgroup = re.findall(r'^\s*(\d+)\s+(\d+)\s+(.*\d{2}:\d{2}:\d{2}\s+\d{4})\s+([\d:]+)\s+(.*)$', line)[0]
        ppid = allgroup[0]
        pid = allgroup[1]
        lstart = allgroup[2]
        etime = allgroup[3]
        # args = allgroup[4]

        process = {
            "过滤进程的字符串": key,
            "父进程ID": ppid,
            "进程ID": pid,
            "进程启动时刻": lstart,
            "进程运行时长": etime,
            # "进程运行的命令": args,
        }
        server[name].append(process)
    servers.append(server)

argNum = len(sys.argv)
if argNum == 2:
	arg1 = sys.argv[1]
	if arg1 == 'db':
		ps(dbKey, "达梦数据库")
	elif arg1 == 'relay':
		ps(mediaKey, "媒体")
		ps(mPkey, "媒体守护进程")
	elif arg1 == 'sip':
		ps(sipKey, "信令")
		ps(sPkey, "信令守护进程")
	elif arg1 == 'app':
		ps(appKey, "应用")
	elif arg1 == 'sync':
		ps(syncMainKey, "同步主程序")
		ps(syncJettyKey, "同步WEB程序")
	elif arg1 == 'conf':
		ps(confKey, "集中配置")
	elif arg1 == 'upgrade':
		ps(upgradeKey, "升级")
	elif arg1 == 'vt':
		ps(vtKey, "虚拟终端")
		#ps(mbKey, "虚拟终端代理")
		ps(streamKey, "虚拟终端代理")
		ps(vtPkey, "虚拟终端守护进程")
	else:
		print 'args is db|relay|sip|app|sync|conf|upgrade|vt'
else:
	ps(dbKey, "达梦数据库")
	ps(mediaKey, "媒体")
	ps(mPkey, "媒体守护进程")
	ps(sipKey, "信令")
	ps(sPkey, "信令守护进程")
	ps(appKey, "应用")
	ps(syncMainKey, "同步主程序")
	ps(syncJettyKey, "同步WEB程序")
	ps(confKey, "集中配置")
	ps(upgradeKey, "升级")
	ps(vtKey, "虚拟终端")
	ps(streamKey, "虚拟终端代理")
	ps(vtPkey, "虚拟终端守护进程")


# print json.dumps(servers, sort_keys=True, indent=3)
print json.dumps(servers, indent=3, ensure_ascii=False)

