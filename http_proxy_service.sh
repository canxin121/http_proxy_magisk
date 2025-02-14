#!/system/bin/sh

MODDIR="/data/adb/modules/http_proxy"
PROXY_DIR="/data/adb/http_proxy"
PROXY_LOG="${PROXY_DIR}/proxy.log"
PROXY_BIN="${PROXY_DIR}/http_proxy"
PROXY_CONFIG="${PROXY_DIR}/config.toml"
PID_FILE="${PROXY_DIR}/http_proxy.pid"

# 更新模块描述的函数
update_description() {
    sed -i "s/description=.*/description=Status: $1/" "$MODDIR/module.prop"
}

(
    # 等待设备启动完成
    until [ $(getprop init.svc.bootanim) = "stopped" ]; do
        sleep 10
    done
    
    # 检查二进制文件和配置文件是否存在
    # 如果不存在则退出并且更新模块描述
    if [ ! -f "$PROXY_BIN" ]; then
        update_description "Error: Binary not found"
        exit 1
    fi
    
    if [ ! -f "$PROXY_CONFIG" ]; then
        update_description "Error: Config not found"
        exit 1
    fi
    
    # 设置环境和权限
    export HTTP_PROXY_CONFIG_PATH="$PROXY_CONFIG"
    export RUST_LOG="error"
    chmod 755 "$PROXY_BIN"
    
    # 启动服务
    $PROXY_BIN > $PROXY_LOG 2>&1 &
    echo $! > "$PID_FILE"
    
    # 检查是否成功启动
    sleep 1
    if kill -0 "$(cat $PID_FILE)" 2>/dev/null; then
        update_description "Running"
    else
        error_msg=$(tail -n 1 "$PROXY_DIR/proxy.log")
        update_description "Failed: $error_msg"
    fi
)&