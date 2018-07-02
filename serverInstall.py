#!/usr/bin/env python
# coding=utf-8

import os
import sys
import json
import commands
from collections import OrderedDict

argStr = sys.argv[1]

thisDir = os.path.dirname(os.path.abspath(__file__))

argJson = json.loads(argStr, object_pairs_hook=OrderedDict)
#print argJson

if argJson['serverName'] == 'message':
    del argJson['serverName']
    if argJson["action"] == "install":
        #防止顺序不对，重新按照列表 orderKey的顺序生成字典 argJsonOrder
        orderKey = ["action", "localIP", "appIP", "syncIP", "sipIP", "relayIP", "vtIP", "username", "password"]
        argJsonOrder = OrderedDict()
        for key in orderKey:
            argJsonOrder[key] = argJson[key]
        #print argJsonOrder

        argValuesStr = ' '.join(argJsonOrder.values())
        #print argValuesStr
        out = commands.getstatusoutput('sh %s/messageInstall.sh %s' %(thisDir, argValuesStr))
        print out[1]
    elif argJson["action"] == "update":
        out = commands.getstatusoutput('sh %s/messageInstall.sh %s' %(thisDir, argJson["action"]))
        print out[1]
elif argJson['serverName'] == 'topology':
    del argJson['serverName']
    if argJson["action"] == "install":
        #防止顺序不对，重新按照列表 orderKey的顺序生成字典 argJsonOrder
        orderKey = ["action", "localIP", "switchIP"]
        argJsonOrder = OrderedDict()
        for key in orderKey:
            argJsonOrder[key] = argJson[key]
        #print argJsonOrder

        argValuesStr = ' '.join(argJsonOrder.values())
        #print argValuesStr
        out = commands.getstatusoutput('sh %s/topology.sh %s' %(thisDir, argValuesStr))
        print out[1]

