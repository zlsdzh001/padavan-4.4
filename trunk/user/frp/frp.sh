#!/bin/sh
frpc_enable=`nvram get frpc_enable`
frps_enable=`nvram get frps_enable`
http_username=`nvram get http_username`
frpc_path="/etc/storage/frpc"
frps_path="/etc/storage/frps"

check_frp () 
{
	check_net
	result_net=$?
	if [ "$result_net" = "1" ]; then
		if [ -z "`pidof frpc`" ] && [ "$frpc_enable" = "1" ];then
			r=$(down_frpc)
			if [ "$r" == "1" ]; then
				frp_start
			fi
		fi
		if [ -z "`pidof frps`" ] && [ "$frps_enable" = "1" ];then
			r=$(down_frps)
			if [ "$r" == "1" ]; then
				frp_start
			fi
		fi
	fi
}

down_frpc()
{
	FRP_URL="https://opt.cn2qq.com/opt-file/frpc"
	if [ ! -f "$frpc_path" ]; then
		wget -t5 --timeout=60 --no-check-certificate -O $frpc_path $FRP_URL; 
		if [ ! -f "$frpc_path" ]; then
			logger -t "frp" "无法下载应用程序frpc，请确认网络正常，有充足的空间在/etc/storage/，请手工重启再试！"
			echo "0"
			return
		fi
	fi
	mkdir -p /tmp/frp
	rm -rf /tmp/frp/frpc
	chmod +x $frpc_path && ln -s $frpc_path /tmp/frp/frpc
	echo "1"
}

down_frps()
{
	FRP_URL="https://opt.cn2qq.com/opt-file/frps"
	if [ ! -f "$frps_path" ]; then
		wget -t5 --timeout=60 --no-check-certificate -O $frps_path $FRP_URL; 
		if [ ! -f "$frps_path" ]; then
			logger -t "frp" "无法下载应用程序frps，请确认网络正常，有充足的空间在/etc/storage/，请手工重启再试！"
			echo "0"
			return
		fi
	fi
	mkdir -p /tmp/frp
	rm -rf /tmp/frp/frps
	chmod +x $frps_path && ln -s $frps_path /tmp/frp/frps
	echo "1"
}

check_net() 
{
	/bin/ping -c 3 223.5.5.5 -w 5 >/dev/null 2>&1
	if [ "$?" == "0" ]; then
		return 1
	else
		return 2
		logger -t "frp" "检测到互联网未能成功访问,稍后再尝试启动frp"
	fi
}

frp_start () 
{
	/etc/storage/frp_script.sh
	sed -i '/frp/d' /etc/storage/cron/crontabs/$http_username
	cat >> /etc/storage/cron/crontabs/$http_username << EOF
*/1 * * * * /bin/sh /usr/bin/frp.sh C >/dev/null 2>&1
EOF
	[ ! -z "`pidof frpc`" ] && logger -t "frp" "frpc启动成功"
	[ ! -z "`pidof frps`" ] && logger -t "frp" "frps启动成功"
}

frp_close () 
{
	if [ "$frpc_enable" = "0" ]; then
		if [ ! -z "`pidof frpc`" ]; then
		killall -9 frpc frp_script.sh
		[ -z "`pidof frpc`" ] && logger -t "frp" "已停止 frpc"
	    fi
	fi
	if [ "$frps_enable" = "0" ]; then
		if [ ! -z "`pidof frps`" ]; then
		killall -9 frps frp_script.sh
		[ -z "`pidof frps`" ] && logger -t "frp" "已停止 frps"
	    fi
	fi
	if [ "$frpc_enable" = "0" ] && [ "$frps_enable" = "0" ]; then
	sed -i '/frp/d' /etc/storage/cron/crontabs/$http_username
    fi
}


case $1 in
start)
	frp_start
	;;
stop)
	frp_close
	;;
C)
	check_frp
	;;
esac
