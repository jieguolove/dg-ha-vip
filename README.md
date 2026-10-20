# dg-ha-vip
oracle adg ha vip
参看：https://www.modb.pro/db/1995717965317234688

在adg中使用vip的目的是为了应用程序可以在adg发生切换后不用修改数据源ip，从而大大减少业务中断的时间。
此次部署vip脚本的同时需屏蔽掉messages的su日志输出，避免日志无限增大。

相同网卡配置的主备两台机器部署和运行的脚本完全一致。

检查public业务网卡名称：
[root@euler01 etc]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
inet 127.0.0.1/8 scope host lo
valid_lft forever preferred_lft forever
inet6 ::1/128 scope host noprefixroute
valid_lft forever preferred_lft forever
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
link/ether 00:50:56:9f:4f:2f brd ff:ff:ff:ff:ff:ff
inet 192.168.207.47/24 brd 192.168.207.255 scope global noprefixroute ens33
valid_lft forever preferred_lft forever
3: ens36: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
link/ether 00:50:56:9f:bd:a0 brd ff:ff:ff:ff:ff:ff
inet 10.10.10.47/24 brd 10.10.10.255 scope global noprefixroute ens36
valid_lft forever preferred_lft forever
inet6 fe80::250:56ff:fe9f:bda0/64 scope link noprefixroute
valid_lft forever preferred_lft forever

[root@euler01 etc]# cat /etc/rc.local
添加

/etc/vip_check.sh > /dev/null 2>&1 &
[root@euler01 etc]#
注意权限：chmod +x /etc/rc.d/rc.local
[root@euler01 etc]# ll /etc/rc.d/rc.local
-rwxr-xr-x. 1 root root 510 Dec 2 09:48 /etc/rc.d/rc.local
[root@euler01 etc]#

vip_check.sh脚本内容：

[root@euler01 etc]# cat /etc/vip_check.sh

#!/bin/bash
step=3
while true; do
    /etc/vip_dg.sh > /dev/null 2>&1
    sleep $step
done

vip_dg.sh脚本内容：
[root@euler01 etc]# cat /etc/vip_dg.sh

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

系统启动后可以看到脚本在运行中：
[root@euler01 etc]# ps -ef|grep vip
root 1085 1 0 10:44 ? 00:00:01 /bin/bash /etc/vip_check.sh
root 175922 5190 0 12:48 pts/0 00:00:00 grep --color=auto vip
[root@euler01 etc]#

当前作为主库，207.39浮动ip按预期挂在了ens33:1上。

[root@euler01 etc]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
inet 127.0.0.1/8 scope host lo
valid_lft forever preferred_lft forever
inet6 ::1/128 scope host noprefixroute
valid_lft forever preferred_lft forever
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
link/ether 00:50:56:9f:4f:2f brd ff:ff:ff:ff:ff:ff
inet 192.168.207.47/24 brd 192.168.207.255 scope global noprefixroute ens33
valid_lft forever preferred_lft forever
inet 192.168.207.39/24 brd 192.168.207.255 scope global secondary ens33:1
valid_lft forever preferred_lft forever
inet6 fe80::250:56ff:fe9f:4f2f/64 scope link noprefixroute
valid_lft forever preferred_lft forever
3: ens36: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
link/ether 00:50:56:9f:bd:a0 brd ff:ff:ff:ff:ff:ff
inet 10.10.10.47/24 brd 10.10.10.255 scope global noprefixroute ens36
valid_lft forever preferred_lft forever
inet6 fe80::250:56ff:fe9f:bda0/64 scope link noprefixroute
valid_lft forever preferred_lft forever

系统日志中每3秒输出su记录：
[root@euler01 etc]# tail -f /var/log/messages
Dec 2 12:36:38 euler01 su[159264]: (to oracle) root on none
Dec 2 12:36:41 euler01 su[159336]: (to oracle) root on none
Dec 2 12:36:44 euler01 su[159405]: (to oracle) root on none
Dec 2 12:36:47 euler01 su[159474]: (to oracle) root on none
Dec 2 12:36:50 euler01 su[159544]: (to oracle) root on none
Dec 2 12:36:53 euler01 su[159613]: (to oracle) root on none
Dec 2 12:36:57 euler01 su[159683]: (to oracle) root on none
Dec 2 12:37:00 euler01 su[159752]: (to oracle) root on none
Dec 2 12:37:03 euler01 su[159825]: (to oracle) root on none
Dec 2 12:37:06 euler01 su[159894]: (to oracle) root on none
Dec 2 12:37:09 euler01 su[159964]: (to oracle) root on none
^C

如何屏蔽掉su的日志记录不输出到messages呢？

检查rsyslog服务：
[root@euler01 etc]# systemctl status rsyslog
● rsyslog.service - System Logging Service
Loaded: loaded (/usr/lib/systemd/system/rsyslog.service; enabled; preset: enabled)
Active: active (running) since Tue 2025-12-02 10:44:52 CST; 1h 53min ago
Docs: man:rsyslogd(8)
https://www.rsyslog.com/doc/
Process: 1187 ExecStartPost=/bin/bash /usr/bin/timezone_update.sh (code=exited, status=0/SUCCESS)
Main PID: 1113 (rsyslogd)
Tasks: 3 (limit: 47328)
Memory: 13.0M ()
CGroup: /system.slice/rsyslog.service
└─1113 /usr/sbin/rsyslogd -n -i/var/run/rsyslogd.pid

Dec 02 10:44:52 euler01 systemd[1]: Starting System Logging Service…
Dec 02 10:44:52 euler01 rsyslogd[1113]: imjournal: filecreatemode is not set, using default 0644 [v8.2312.0 try https://www.rsyslog.com/e/2186 ]
Dec 02 10:44:52 euler01 rsyslogd[1113]: [origin software=“rsyslogd” swVersion=“8.2312.0” x-pid=“1113” x-info=“https://www.rsyslog.com”] start
Dec 02 10:44:52 euler01 rsyslogd[1113]: imjournal: No statefile exists, /run/log/imjournal.state will be created (ignore if this is first run): No such file or directory [v8.2>
Dec 02 10:44:52 euler01 systemd[1]: Started System Logging Service.
Dec 02 10:44:52 euler01 rsyslogd[1113]: imjournal: journal files changed, reloading… [v8.2312.0 try https://www.rsyslog.com/e/0 ]

修改/etc/rsyslog.conf文件，找到此行/var/log/messages添加User oracle,auth.none

[root@euler01 etc]# vi /etc/rsyslog.conf

— 屏蔽 oracle 用户的 session 日志 —
:programname, isequal, “systemd”
& :msg, contains, “User oracle”
& :msg, regex, “session-c[0-9]+\.scope”
stop

*.info;mail.none;authpriv.none;cron.none;auth.none /var/log/messages

~
~
“rsyslog.conf” 56L, 2181B written
[root@euler01 etc]# cat /etc/rsyslog.conf|grep auth.

*.info;mail.none;authpriv.none;cron.none;auth.none /var/log/messages

重启rsyslog服务：
[root@euler01 etc]# systemctl restart rsyslog

再次检查/var/log/message，确定没有再输出su记录，搞定！

[root@euler01 etc]# tail -f /var/log/messages
Dec 2 12:44:41 euler01 systemctl[170182]: [systemctl restart rsyslog] called by PID 5190 (-bash)
Dec 2 12:44:41 euler01 systemd[1]: Stopping System Logging Service…
Dec 2 12:44:42 euler01 rsyslogd[1113]: [origin software=“rsyslogd” swVersion=“8.2312.0” x-pid=“1113” x-info=“https://www.rsyslog.com”] exiting on signal 15.
Dec 2 12:44:42 euler01 systemd[1]: rsyslog.service: Deactivated successfully.
Dec 2 12:44:42 euler01 systemd[1]: Stopped System Logging Service.
Dec 2 12:44:42 euler01 systemd[1]: Starting System Logging Service…
Dec 2 12:44:42 euler01 rsyslogd[170185]: imjournal: filecreatemode is not set, using default 0644 [v8.2312.0 try https://www.rsyslog.com/e/2186 ]
Dec 2 12:44:42 euler01 rsyslogd[170185]: [origin software=“rsyslogd” swVersion=“8.2312.0” x-pid=“170185” x-info=“https://www.rsyslog.com”] start
Dec 2 12:44:42 euler01 rsyslogd[170185]: imjournal: journal files changed, reloading… [v8.2312.0 try https://www.rsyslog.com/e/0 ]
Dec 2 12:44:42 euler01 systemd[1]: Started System Logging Service.

连接服务ip测试：
[root@euler01 etc]# su - oracle

[oracle@euler01 ~]$ sqlplus jyc/jyc@192.168.207.39:1521/bims

SQL*Plus: Release 11.2.0.4.0 Production on Tue Dec 2 13:10:18 2025

Copyright © 1982, 2013, Oracle. All rights reserved.

Connected to:
Oracle Database 11g Enterprise Edition Release 11.2.0.4.0 - 64bit Production
With the Partitioning, OLAP, Data Mining and Real Application Testing options

SQL> select * from a;

    ID
     1
     2
SQL>
