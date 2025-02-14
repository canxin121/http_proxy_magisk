#!/sbin/sh
# This script will be executed in late_start service mode.

MAGISK_VER_CODE=$(getprop magisk.version_code)

export DING_CONFIG_FILE="/data/adb/http_proxy/config.toml"

/data/adb/http_proxy/http_proxy &