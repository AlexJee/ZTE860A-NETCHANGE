#!/system/bin/sh

# ZTE B860A netchange.sh
# eth0: iTV cable, wlan0: Wifi internet
# Author: http://github.com/nadoo
# Date: 2016-10-24

# mount -o rw,remount /system
# vi /system/bin/netchange.sh
# chmod 0755 /system/bin/netchange.sh
# echo "/system/bin/netchange.sh &" >> /system/bin/init.zte.post_boot.sh

# disable upgrade
pm block com.ztestb.upgrade

# wait for wlan or itv link up
while [ "$(getprop net.zte.eth.netstate)" != "CONNECTED" ] && [ "$(getprop net.zte.wifi.netstate)" != "CONNECTED" ]
do
        sleep 10
done

#we need to wait for itv connection to be established
sleep 10

# if you have wifi and eth0 connected, then you should have the following network config
# default via 192.168.1.1 dev wlan0
# default via xxx.xxx.xxx.x dev eth0
# xxx.xxx.xxx.x dev eth0  scope link
# xxx.xxx.xxx.x/xx dev eth0  proto kernel  scope link  src xxx.xxx.xxx.x
# 192.168.1.0/24 dev wlan0  scope link
# 192.168.1.0/24 dev wlan0  proto kernel  scope link  src 192.168.1.xxx

# 0:wifi 1:itv
itv=1

wifi_if="wlan0"
itv_if="eth0"

while :
do
	# wifi gateway and dns
	wifi_gw=$(getprop dhcp.wlan0.gateway)
	wifi_dns=$(getprop dhcp.wlan0.dns1)
	# itv gateway and dns
	itv_gw=$(getprop dhcp.eth0.gateway)
	itv_dns=$(getprop dhcp.eth0.dns1)

    # check whether itv is current window
    check_app=$( dumpsys window windows | grep -E 'mCurrentFocus|mFocusedApp' | grep -E com.zte.browser | busybox wc -l )
    if [ $check_app != 0 ] && [ $itv != 1 ]; then
        if [ $itv_gw != "" ]; then
        	echo "=itv started..." >> /cache/netchange.log
            itv=1

			check_wifi=$( ip route | grep "$wifi_if" | busybox wc -l )
            if [ $check_wifi = 3 ]; then
                ip route delete default via $wifi_gw dev $wifi_if
            fi
            
            check_itv=$( ip route | grep "$itv_if" | busybox wc -l )
            if [ $check_itv != 3 ]; then
                ip route add default via $itv_gw dev $itv_if
            fi
            
            ndc resolver flushdefaultif
            ndc resolver setifdns $itv_if "" $itv_dns
            ndc resolver setdefaultif $itv_if
            sleep 1
            echo "=switched to $itv_if..." >> /cache/netchange.log
            echo "=gateway:$itv_gw dns:$itv_dns" >> /cache/netchange.log
        fi
    elif [ $check_app = 0 ] && [ $itv = 1 ]; then
        if [ $wifi_gw != "" ]; then
        	echo "=itv stopped..." >> /cache/netchange.log
            itv=0
            
            check_itv=$( ip route | grep "$itv_if" | busybox wc -l )
            if [ $check_itv = 3 ]; then
                ip route del default via $itv_gw dev $itv_if
            fi
            
            check_wifi=$( ip route | grep "$wifi_if" | busybox wc -l )
            if [ $check_wifi != 3 ]; then
                ip route add default via $wifi_gw dev $wifi_if
            fi
            
            ndc resolver flushdefaultif
            ndc resolver setifdns $wifi_if "" $wifi_dns
            ndc resolver setdefaultif $wifi_if
            sleep 1
            echo "=switched to $wifi_if..." >> /cache/netchange.log
            echo "=gateway:$wifi_gw dns:$wifi_dns" >> /cache/netchange.log
        fi
    fi
   
    sleep 5
        
done 
