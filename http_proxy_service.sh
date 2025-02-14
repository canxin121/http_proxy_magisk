#!/system/bin/sh

(
    until [ $(getprop init.svc.bootanim) = "stopped" ]; do
        sleep 10
    done
    
    export HTTP_PROXY_CONFIG_PATH="/data/adb/http_proxy/config.toml"
    
    if [ -f "/data/adb/http_proxy/http_proxy" ]; then
        chmod 755 /data/adb/http_proxy/http_proxy
        /data/adb/http_proxy/http_proxy &
    else
        echo "File '/data/adb/http_proxy/http_proxy' not found"
    fi
)&