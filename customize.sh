#!/system/bin/sh

# 基本配置
SKIPUNZIP=1
SKIPMOUNT=false
PROPFILE=true
POSTFSDATA=false
LATESTARTSERVICE=true

# 检查安装环境
if [ "$BOOTMODE" != true ]; then
    abort "请在Magisk Manager中安装"
fi

# 设置service目录
service_dir="/data/adb/service.d"
if [ "$KSU" = "true" ]; then
    [ "$KSU_VER_CODE" -lt 10683 ] && service_dir="/data/adb/ksu/service.d"
    elif [ "$APATCH" = "true" ]; then
    APATCH_VER=$(cat "/data/adb/ap/version")
fi

# 创建service目录
mkdir -p "${service_dir}"

# 解压文件
ui_print "- 正在安装HTTP代理模块"
unzip -o "$ZIPFILE" -x 'META-INF/*' -d "$MODPATH" >&2

# 创建并移动http_proxy目录
ui_print "- 移动http_proxy到系统目录"
mkdir -p /data/adb/http_proxy/
# 在移动前先删除旧文件
rm -f /data/adb/http_proxy/*
mv "$MODPATH/http_proxy/"* /data/adb/http_proxy/

# 移动service脚本
ui_print "- 移动服务脚本"
# 在移动前先删除旧文件
rm -f "${service_dir}/http_proxy_service.sh"
mv "$MODPATH/http_proxy_service.sh" "${service_dir}/http_proxy_service.sh"

# 设置权限
ui_print "- 设置权限"
set_perm_recursive /data/adb/http_proxy/ 0 0 0755 0644
set_perm ${service_dir}/http_proxy_service.sh 0 0 0755

# 清理工作
rm -rf "$MODPATH/http_proxy"
rm -f "$MODPATH/http_proxy_service.sh"

ui_print "- 安装完成，请重启设备"
