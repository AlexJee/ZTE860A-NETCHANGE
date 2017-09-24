#!/system/bin/sh

# get mem from fingerprint
var=`getprop ro.build.fingerprint | awk -F, '{print $1}'`
mem=`echo $var`
case "$mem" in
    "512MB")
        /system/bin/sh /system/bin/ramzswap_mount.sh
        ;;
esac

# increase receive socket buffer
echo 131072 > /proc/sys/net/core/rmem_default
echo 4194304 > /proc/sys/net/core/rmem_max
echo 4194304 > /proc/sys/net/core/wmem_max
#echo 20000  21000 > /proc/sys/net/ipv4/ip_local_port_range
echo 2 > /proc/sys/net/ipv4/conf/eth0/force_igmp_version
echo 5 > /proc/sys/net/ipv4/tcp_syn_retries
echo 5 > /proc/sys/net/ipv4/tcp_synack_retries


echo 2 > /sys/module/amvdec_h264/parameters/error_recovery_mode
echo 2 > /sys/module/amvdec_mpeg12/parameters/error_frame_skip_level


echo 4096 174760 11264000 > /proc/sys/net/ipv4/tcp_rmem
setprop net.tcp.buffersize.default 4096,174760,11264000,4096,16384,4194304
echo 4096 16384 4194304 > /proc/sys/net/ipv4/tcp_wmem

var=`cat /sys/devices/platform/aml_sdhc.0/mmc_host/emmc/emmc:0001/name`
setprop ro.product.flash.name $var

setprop hw.encoder.forcemode 2 
setprop hw.encoder.min_qp 28 
setprop hw.encoder.max_qp 38

adbd&
busybox telnetd -l /system/bin/sh&

settings put global install_non_market_apps 1

setprop config.Android.AppInstallCtrl 3
setprop ro.adb.secure 0
setprop ro.secure 0
setprop ro.debuggable 1
setprop persist.service.adb.enable 1
setprop persist.adb.tcp.port 5555

#chmod 777 /dev/amvenc_avc
#chmod 777 /dev/video13
chmod 777 /dev/video11

chmod 0777 /data/media                        
chmod 0777 /data/media/0

/system/bin/netchange.sh &
