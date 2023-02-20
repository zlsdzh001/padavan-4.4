#!/bin/sh


start() {   if grep -q 'mt76x3_ap' /proc/modules ; then
	    ralinkiappd -wi rai0 -d 0          &
	    sysctl -wq net.ipv4.neigh.rai0.base_reachable_time_ms=10000
	    sysctl -wq net.ipv4.neigh.rai0.delay_first_probe_time=1
            else
	    if grep -q 'rai0' /proc/interrupts; then
	    ralinkiappd -wi rai0 -wi ra0 -d 0   &
	    sysctl -wq net.ipv4.neigh.rai0.base_reachable_time_ms=10000
	    sysctl -wq net.ipv4.neigh.rai0.delay_first_probe_time=1
	    else
	    ralinkiappd -wi rax0 -wi ra0 -d 0   &
	    sysctl -wq net.ipv4.neigh.rax0.base_reachable_time_ms=10000
	    sysctl -wq net.ipv4.neigh.rax0.delay_first_probe_time=1	    
	    fi
	    fi
	    sysctl -wq net.ipv4.neigh.br0.base_reachable_time_ms=10000
	    sysctl -wq net.ipv4.neigh.br0.delay_first_probe_time=1
	    sysctl -wq net.ipv4.neigh.eth2.base_reachable_time_ms=10000
	    sysctl -wq net.ipv4.neigh.eth2.delay_first_probe_time=1
	    sysctl -wq net.ipv4.neigh.ra0.base_reachable_time_ms=10000
	    sysctl -wq net.ipv4.neigh.ra0.delay_first_probe_time=1
	    iptables -A INPUT -i br0 -p tcp --dport 3517 -j ACCEPT
	    iptables -A INPUT -i br0 -p udp --dport 3517 -j ACCEPT 

	    # ap relay monitor [simonchen]
	    if [ ! -x /etc/storage/sh_ezscript.sh ]; then
		cp /etc_ro/sh_ezscript.sh /etc/storage/sh_ezscript.sh
	    fi
	    if [ -x /etc/storage/ap_script.sh ]; then
		/etc/storage/ap_script.sh >/dev/null 2>&1 &
	    else
		cp /etc_ro/ap_script.sh /etc/storage/ap_script.sh
	    fi
}





stop() {
    pid=`pidof ralinkiappd`
    if [ "$pid" != "" ]; then
        killall -q  ralinkiappd
	sleep 1
	killall -q  ralinkiappd
	sleep 1
    fi
    
}


case "$1" in
        start)
            start
            ;;

        stop)
            stop
            ;;

        restart)
            stop
            start
            ;;

        *)
            echo $"Usage: $0 {start|stop|restart}"
esac
