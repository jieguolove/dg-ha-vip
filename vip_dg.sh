#!/bin/bash
dbstats=`su - oracle -c "echo -e 'set pagesize 0\nselect open_mode from v\\$database;' | sqlplus -S / as sysdba"|grep WRITE|wc -l`
ip=`/usr/sbin/ip a|grep ens33:1|wc -l`
 
if [[ "${dbstats}" -eq 1 ]] ; then
    if [[ "${ip}" -eq 0 ]]; then
    /usr/sbin/ifconfig ens33:1 192.168.207.39 netmask 255.255.255.0 up
    /usr/sbin/arping -I ens33 -b -s 192.168.207.39 192.168.207.1 -c 3
    fi
else
    if [[ "${ip}" -gt 0 ]]; then
    /usr/sbin/ifconfig ens33:1 down
    fi
fi
