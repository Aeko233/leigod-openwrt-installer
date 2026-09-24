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

- **安装**：自动检测依赖并安装雷神加速器插件。
- **卸载**：清理并卸载雷神加速器插件及相关配置。
- **重装/更新**：重新安装或更新当前插件。
- **禁用/启用服务**：控制加速器后台服务的启停。
- **切换运行模式**：在 TUN 模式与 Tproxy 模式之间切换。
- **安装兼容性依赖**：安装加速相关的网络组件。
- **禁用/启用 IPv6**：根据需要开关 IPv6。
- **安装软件包版本 (IPK/APK)**：按系统环境自动下载并安装对应的软件包。
- **帮助**：查看简要说明。
- **退出**：退出脚本。

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
