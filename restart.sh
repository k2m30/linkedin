#!/usr/bin/env bash

kill $(ps aux | grep thin | awk '{print $2}')
nohup thin start -a 0.0.0.0 > /dev/null 2>&1 &