#!/usr/bin/env bash

echo killing Thin..
kill $(ps aux | grep thin | awk '{print $2}')

echo start thin again..
nohup thin start -a 0.0.0.0 > /dev/null 2>&1 &