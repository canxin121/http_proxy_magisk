# HTTP Proxy Magisk

# 使用说明

## 单代理(仅本程序)

1. 在 Magisk 中安装本模块
2. 配置/data/adb/http_proxy/config.toml
3. 在所需代理的软件中配置代理地址

## 多代理并存

以 clash 为例, 启动本程序后，手动添加一个代理节点如:

```yaml
- name: "http_proxy"
  type: http
  server: localhost
  port: 3000
```

并在分流中将本程序的流量设置为直连来防止回环:

可以使用`IP-CIDR`来将远程代理服务器的 ip 设置为 DIRECT

```yaml
- "IP-CIDR,1.1.1.1/32,DIRECT"
```

如果代理工具支持, 也可以使用`PROCESS-NAME`来将进程设置为 DIRECT

```yaml
- "PROCESS-NAME,http_proxy,DIRECT"
```

## 配置格式

```toml
# 本地代理地址
local_address = "127.0.0.1:3000"

# 远程代理服务器配置
[remote_proxy_address]
# 仅支持ip, 不支持域名形式
host = "1.1.1.1"
port = 443

# 混淆配置
[obfuscation]
host = "host"
port = 80
```
