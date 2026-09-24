# leigod-openwrt-installer

基于 Shell 脚本的雷神加速器插件管理器，适用于 OpenWrt / ImmortalWrt 系统。

支持常见的 OpenWrt 固件（支持传统 opkg 以及新版 apk 包管理器）。

---

### 使用方法

通过 SSH 登录路由器终端，执行以下命令运行管理器：

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Aeko233/leigod-openwrt-installer/main/leigod.sh)"
```

---

### 功能说明

脚本运行后会显示功能菜单：

- **1. 官方脚本安装**：直接安装雷神官方最新加速引擎，适合只需要通过雷神手机 App 绑定的用户（后台无网页界面）。
- **2. 卸载加速器插件**：清理加速进程、相关防火墙规则以及残留文件。
- **3. 重装 / 更新插件**：重新拉取并安装最新加速核心。
- **4. 启用 / 停止服务**：控制加速器服务的后台运行与开机自启。
- **5. 切换运行模式**：在 TUN 虚拟网卡模式与 Tproxy 透明代理模式之间切换。
- **6. 安装网络优化组件**：补充安装 tc-full、conntrack 等包，优化加速 Ping 值与 NAT 类型识别。
- **7. 开关 IPv6**：根据需要快速切换 IPv6 状态，防止 PC/主机/手游 优先走 IPv6 导致绕过加速代理。
- **8. 安装 LuCI 插件版 (含网页管理界面)**：安装带有路由器后台可视化界面的完整版本（自动匹配新版 apk 与传统 opkg）。
- **9. 代理共存设置**：配置游戏主机/PC 的 IP 绕过 OpenClash/PassWall 等代理，防止游戏流量被外部代理劫持冲突。
- **10. 查看帮助说明**：显示脚本各项功能的详细说明。
- **0. 退出**：退出管理器脚本。

---

### 离线安装包说明

针对使用 `apk` 包管理器的新版固件，可直接使用 `packages/apk/` 目录中的安装包：

```sh
apk add --allow-untrusted ./leigod-acc-*.apk ./luci-app-leigod-acc-*.apk ./luci-i18n-leigod-acc-zh-cn-*.apk
```

---

### 运行依赖

- 基础组件：`libpcap`、`iptables`、`kmod-ipt-nat`、`iptables-mod-tproxy`、`kmod-ipt-tproxy`、`kmod-ipt-ipset`、`ipset`、`kmod-tun`、`curl`、`miniupnpd`
- 优化组件：`tc-full`、`kmod-netem`、`conntrack`、`conntrackd`
- Web 界面兼容层（新版 LuCI）：`luci-compat`
