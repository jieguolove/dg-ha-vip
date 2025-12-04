#!/bin/bash
step=3
while true; do
    /etc/vip_dg.sh > /dev/null 2>&1
    sleep $step
done
