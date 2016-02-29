#!/usr/bin/env bash

echo current puma ID: $(ps aux | grep puma | awk '{print $2}')
echo killing puma..
kill $(ps aux | grep puma | awk '{print $2}')
sleep 2

echo start puma again..
nohup puma config.ru -p 3000 > /dev/null 2>&1 &

echo new puma ID: $(ps aux | grep puma | awk '{print $2}')