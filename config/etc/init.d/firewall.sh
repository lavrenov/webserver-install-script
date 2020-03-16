#!/bin/sh
### BEGIN INIT INFO
# Provides:          server firewall
# Required-Start:    $local_fs $remote_fs $network $syslog $named
# Required-Stop:     $local_fs $remote_fs $network $syslog $named
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# X-Interactive:     true
# Short-Description: firewall
# Description:       firewall
# This script will start the firewall.
### END INIT INFO
IPTABLES="/sbin/iptables"

case "$1" in
    start|restart)
        echo -n "Loading Firewall's Packet Filters\n"
        /etc/iptables.start
        ;;

    stop)
        echo -n "Stopping the firewall (in a closed state)!\n"
        $IPTABLES --flush
        $IPTABLES -X
        $IPTABLES -P INPUT ACCEPT
        $IPTABLES -P OUTPUT ACCEPT
        $IPTABLES -P FORWARD ACCEPT
        ;;

    *)
        echo "Usage: /etc/init.d/firewall.sh {start|stop|restart}"
        exit 1
        ;;

esac
exit 0
