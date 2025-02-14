#!/system/bin/sh

MODDIR="/data/adb/modules/http_proxy"
PROXY_DIR="/data/adb/http_proxy"
PROXY_BIN="${PROXY_DIR}/http_proxy"
PROXY_CONFIG="${PROXY_DIR}/config.toml"
PROXY_PID_FILE="/data/adb/http_proxy/http_proxy.pid"

# 更新模块描述
update_description() {
    local status="$1"
    sed -i "s/description=.*/description=HTTP Proxy Status: ${status}/" "$MODDIR/module.prop"
}

# 检查环境
check_env() {
    # 检查二进制文件
    if [ ! -f "$PROXY_BIN" ]; then
        update_description "Error: Binary not found"
        return 1
    fi
    
    # 检查配置文件
    if [ ! -f "$PROXY_CONFIG" ]; then
        update_description "Error: Config file not found"
        return 1
    fi
    
    # 设置权限
    chmod 755 "$PROXY_BIN"
    return 0
}

# 启动服务
start_service() {
    if ! check_env; then
        return 1
    fi
    
    # 设置环境变量并启动
    export HTTP_PROXY_CONFIG_PATH="$PROXY_CONFIG"
    $PROXY_BIN > /dev/null 2>&1 &
    
    # 检查是否成功启动
    sleep 1
    if pidof http_proxy > /dev/null; then
        echo $! > "$PROXY_PID_FILE"
        update_description "Running"
    else
        local error_msg=$(su -c "$PROXY_BIN" 2>&1 | head -n 1)
        update_description "Start failed: $error_msg"
        return 1
    fi
}

# 停止服务
stop_service() {
    if [ -f "$PROXY_PID_FILE" ]; then
        local PID=$(cat "$PROXY_PID_FILE")
        kill "$PID" 2>/dev/null
        rm -f "$PROXY_PID_FILE"
    else
        killall http_proxy 2>/dev/null
    fi
    update_description "Stopped"
}

# 主逻辑
if [ -f "$PROXY_PID_FILE" ] && kill -0 "$(cat "$PROXY_PID_FILE")" 2>/dev/null; then
    stop_service
else
    start_service
fi