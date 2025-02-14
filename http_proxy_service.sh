#!/system/bin/sh

MODDIR="/data/adb/modules/http_proxy_magisk"
PROXY_DIR="/data/adb/http_proxy"
PROXY_LOG="${PROXY_DIR}/proxy.log"
PROXY_BIN="${PROXY_DIR}/http_proxy"
PROXY_CONFIG="${PROXY_DIR}/config.toml"
PID_FILE="${PROXY_DIR}/http_proxy.pid"


# 更新模块描述
update_description() {
    local status="$1"
    echo "Updating module description to: ${status}"
    sed -i "s/^description=.*/description=${status}/g" "$MODDIR/module.prop"
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

(
    # 等待设备启动完成
    until [ $(getprop init.svc.bootanim) = "stopped" ]; do
        sleep 10
    done
    
    # 检查二进制文件和配置文件是否存在
    # 如果不存在则退出并且更新模块描述
    if [ ! -f "$PROXY_BIN" ]; then
        update_description "❌ Binary not found"
        exit 1
    fi
    
    if [ ! -f "$PROXY_CONFIG" ]; then
        update_description "❌ Config not found"
        exit 1
    fi
    
    # 设置环境和权限
    export HTTP_PROXY_CONFIG_PATH="$PROXY_CONFIG"
    chmod 755 "$PROXY_BIN"
    
    # 启动服务
    $PROXY_BIN > $PROXY_LOG 2>&1 &
    echo $! > "$PID_FILE"
    
    # 检查是否成功启动
    sleep 1
    if kill -0 "$(cat $PID_FILE)" 2>/dev/null; then
        update_description "✅ Running at $(get_local_address)"
        start_process_monitor
    else
        error_msg=$(tail -n 1 "$PROXY_DIR/proxy.log")
        update_description "❌ Failed to start: $error_msg"
        stop_process_monitor
    fi
)&