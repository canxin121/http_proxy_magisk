# 启动服务

MODDIR="/data/adb/modules/http_proxy_magisk"
PROXY_DIR="/data/adb/http_proxy"
PROXY_BIN="${PROXY_DIR}/http_proxy"
PROXY_LOG="${PROXY_DIR}/proxy.log"
PROXY_CONFIG="${PROXY_DIR}/config.toml"
PROXY_PID_FILE="/data/adb/http_proxy/http_proxy.pid"

# 更新模块描述
update_description() {
    local status="$1"
    echo "Updating module description to: ${status}"
    sed -i "s/^description=.*/description=${status}/g" "$MODDIR/module.prop"
}

# 检查环境
check_env() {
    echo "Checking environment..."
    
    # 检查二进制文件
    if [ ! -f "$PROXY_BIN" ]; then
        echo "Error: Binary not found at $PROXY_BIN"
        update_description "❌ Binary not found"
        return 1
    fi
    echo "Binary file check passed"
    
    # 检查配置文件
    if [ ! -f "$PROXY_CONFIG" ]; then
        echo "Error: Config file not found at $PROXY_CONFIG"
        update_description "❌ Config not found"
        return 1
    fi
    echo "Config file check passed"
    
    # 设置权限
    echo "Setting binary permissions..."
    chmod 755 "$PROXY_BIN"
    echo "Environment check completed successfully"
    return 0
}

get_local_address() {
    grep '^local_address' "$PROXY_CONFIG" | cut -d'"' -f2
}

start_process_monitor() {
    local monitor_pid_file="${PROXY_DIR}/monitor.pid"
    
    # 检查是否已有监控进程在运行
    if [ -f "$monitor_pid_file" ]; then
        local existing_pid=$(<"$monitor_pid_file")
        if kill -0 "$existing_pid" 2>/dev/null; then
            echo "Monitor process already running with PID $existing_pid"
            return
        else
            rm -f "$monitor_pid_file"
        fi
    fi
    
    # 启动新的监控进程
    (
        echo $$ > "$monitor_pid_file"
        while true; do
            if ! pidof http_proxy >/dev/null 2>&1; then
                echo "Proxy process not found, updating description..."
                update_description "❌ Process died unexpectedly"
            fi
            sleep 30  # 每30秒检查一次
        done
    ) &
}

# 停止监控进程
stop_process_monitor() {
    local monitor_pid_file="${PROXY_DIR}/monitor.pid"
    if [ -f "$monitor_pid_file" ]; then
        local monitor_pid=$(<"$monitor_pid_file")
        if kill -0 "$monitor_pid" 2>/dev/null; then
            kill "$monitor_pid"
        fi
        rm -f "$monitor_pid_file"
    fi
}


# 启动服务
start_service() {
    echo "Starting HTTP proxy service..."
    if ! check_env; then
        echo "Environment check failed, cannot start service"
        return 1
    fi
    
    # 设置环境变量并启动
    echo "Setting environment variables and starting proxy..."
    export HTTP_PROXY_CONFIG_PATH="$PROXY_CONFIG"
    $PROXY_BIN >> "$PROXY_LOG" 2>&1 &
    
    # 检查是否成功启动
    echo "Checking if service started successfully..."
    sleep 1
    if pidof http_proxy > /dev/null; then
        echo $! > "$PROXY_PID_FILE"
        echo "Service started successfully"
        update_description "✅ Running at $(get_local_address)"
        start_process_monitor  # 启动监控
        return 0
    else
        local error_msg=$(su -c "$PROXY_BIN" 2>&1 | head -n 1)
        echo "Failed to start service: $error_msg"
        update_description "❌ Failed to start: $error_msg"
        return 1
    fi
}

# 停止服务
stop_service() {
    echo "Stopping HTTP proxy service..."
    stop_process_monitor # 停止监控
    
    if [ -f "$PROXY_PID_FILE" ]; then
        local PID=$(cat "$PROXY_PID_FILE")
        echo "Found PID file, stopping process $PID"
        kill "$PID" 2>/dev/null
        rm -f "$PROXY_PID_FILE"
    else
        echo "No PID file found, trying to kill all http_proxy processes"
        killall http_proxy 2>/dev/null
    fi
    echo "Service stopped"
    update_description "⏹️ Stopped"
}

# 主逻辑
if [ -f "$PROXY_PID_FILE" ] && kill -0 "$(cat "$PROXY_PID_FILE")" 2>/dev/null; then
    echo "Detected running service"
    stop_service
else
    echo "No running service detected, starting..."
    start_service
fi