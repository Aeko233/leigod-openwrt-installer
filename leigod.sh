#!/bin/sh

if [ "$(id -u)" != "0" ]; then
    echo "Error: You must be root to run this script, please use root user"
    exit 1
fi

if [ -e /etc/asus_release ]; then
    echo "TONY 别肘! 我爱 BCM!"
    echo ""
    echo "[ERROR] 检测到 ASUS 路由器，无法运行 OpenWrt LeigodAcc 管理器，你不是 OpenWrt 系统!"

    if [ ! -d /jffs/softcenter ]; then
        echo "[INFO] 检测到官改 or Koolcenter 版本，即将脱离 OpenWrt 管理器运行官方脚本开始安装."
        echo "[INFO] 以下内容均与 OpenWrt 管理器作者无关，本人并无华硕路由器 Debug!"
        echo
        sleep 5
        cd /tmp || { echo "[ERROR] 无法切换到 /tmp 目录"; exit 1; }
        sh -c "$(curl -fsSL http://119.3.40.126/router_plugin_new/plugin_install.sh)"
    fi
    exit 0
fi

if [ -d /userdisk/appdata ]; then
    echo "R u OK?"
    echo ""
    echo "[ERROR] 检测到小米路由器，无法运行 OpenWrt LeigodAcc 管理器，你不是 OpenWrt 系统!"
    name=$(uci get misc.hardware.displayName 2>/dev/null)
    if [[ $? != "0" || -z ${name} ]]; then
        name=$(uci get misc.hardware.model 2>/dev/null)
    fi
    if [[ -n ${name} ]]; then
        echo "[INFO] 小米路由器: ${name}"
        sleep 5
        echo "[INFO] 检测到小米已经解锁了 SSH，即将脱离 OpenWrt 管理器运行官方脚本开始安装."
        echo "[INFO] 以下内容均与 OpenWrt 管理器作者无关，本人并无小米路由器 Debug!"
        echo
        cd /tmp || { echo "[ERROR] 无法切换到 /tmp 目录"; exit 1; }
        sh -c "$(curl -fsSL http://119.3.40.126/router_plugin_new/plugin_install.sh)"
        exit 0
    fi
fi


if which apk >/dev/null 2>&1; then
    PKG_MGR="apk"
elif which opkg >/dev/null 2>&1; then
    PKG_MGR="opkg"
else
    echo "[ERROR] 未检测到 apk 或 opkg 包管理器!"
    exit 1
fi

pkg_update() {
    if [ "$PKG_MGR" = "apk" ]; then
        apk update
    else
        [ -e /var/lock/opkg.lock ] && rm -f /var/lock/opkg.lock
        opkg update
    fi
}

pkg_installed() {
    if [ "$PKG_MGR" = "apk" ]; then
        apk info -e "$1" >/dev/null 2>&1
    else
        opkg list-installed | grep -q "^$1\b"
    fi
}

pkg_install() {
    if [ "$PKG_MGR" = "apk" ]; then
        apk add --allow-untrusted "$@"
    else
        opkg install "$@"
    fi
}

pkg_remove() {
    if [ "$PKG_MGR" = "apk" ]; then
        apk del "$@"
    else
        opkg remove "$@"
    fi
}

pkg_arch() {
    if [ "$PKG_MGR" = "apk" ]; then
        apk --print-arch 2>/dev/null
    else
        opkg print-architecture | awk 'END {print $2}'
    fi
}

if ! grep -qi -E "OpenWrt|LEDE|QWRT|ImmortalWrt|iStoreOS" /etc/openwrt_release; then
    echo "Your system is not supported!"
    echo "[INFO]你的系统可能无法运行 OpenWrt Leigodacc 插件!"
    echo "当前系统环境并非常见或标准的 OpenWrt，可能是论坛版本修改发行版文件导致无法识别"
    echo "可能导致无法正常支持全部依赖，部分组件可能无法正常启用导致加速问题"
    echo "你可以无视风险继续安装，5s 后将进入管理器菜单，详情参考管理器发布于博客信息"
    echo
    sleep 5
fi

if [ -x /usr/sbin/fw4 ] || [ -f /etc/config/firewall ] && grep -q "fw4" /etc/init.d/firewall 2>/dev/null; then
    echo ""
    echo "[WARN] 当前系统使用的是 fw4/nftables (如 ImmortalWrt 24.10+ / OpenWrt 24.10+)"
    echo "[WARN] 雷神加速器官方服务核心 (acc-gw) 原生依赖 iptables / tproxy。"
    echo "[WARN] 请确保系统已安装 iptables-nft、kmod-nft-tproxy、kmod-nft-nat 等兼容层组件。"
    echo ""
    sleep 3
fi

leigod_menu() {
    echo
    echo "=========================================="
    echo "     雷神加速器 OpenWrt 管理器"
    echo "=========================================="
    echo "1. 官方脚本安装 (仅后台服务, 手机App绑定)"
    echo "2. 卸载加速器插件及配置"
    echo "3. 重装 / 更新插件"
    echo "4. 启用 / 停止 加速服务"
    echo "5. 切换运行模式 (TUN / Tproxy)"
    echo "6. 安装网络优化组件 (提升Ping值与NAT类型)"
    echo "7. 开关 IPv6 (防游戏流量绕过加速器, PC/主机/手游通用)"
    echo "8. 安装 LuCI 插件版 (含网页管理界面)"
    echo "9. 代理共存设置 (配置游戏设备绕过科学代理)"
    echo "10. 查看帮助说明"
    echo "0. 退出"
    echo "=========================================="
    echo -n "请输入对应数字并回车: "
}

install_leigodacc() {
    if [ -d /usr/sbin/leigod ]; then
        echo -n "[INFO] 检测到已经安装 LeigodAcc ([1]继续安装 / [2]取消): "
        read choice
        case $choice in
            1)
                ;;
            2)
                return
                ;;
            *)
                echo "[ERROR] 无效的选项，请重新输入"
                return
                ;;
        esac
    fi

    if [ -f /etc/catwrt_release ]; then
        if [ "$PKG_MGR" = "opkg" ] && [ -f /etc/opkg/distfeeds.conf ]; then
            if ! grep -q -E "catwrt|repo.miaoer.xyz" /etc/opkg/distfeeds.conf && ! ip a | grep -q -E "192\.168\.[0-9]+\.[0-9]+|10\.[0-9]+\.[0-9]+\.[0-9]+|172\.1[6-9]\.[0-9]+\.[0-9]+|172\.2[0-9]+\.[0-9]+|172\.3[0-1]\.[0-9]+\.[0-9]+"; then
                echo "[ERROR] 检测到 CatWrt，请先配置 CatWrt 软件源，请使用:"
                echo "Cattools - Apply_repo"
                echo
                echo "在正确启用软件源后即可获取雷神加速器插件完整支持(可能)"
                cattools
                return
            fi
        fi
    else
        if [ "$PKG_MGR" = "opkg" ]; then
            [ -f /etc/opkg/customfeeds.conf ] && echo "cat /etc/opkg/customfeeds.conf" && cat /etc/opkg/customfeeds.conf
            [ -f /etc/opkg/distfeeds.conf ] && echo "cat /etc/opkg/distfeeds.conf" && cat /etc/opkg/distfeeds.conf
        fi
        if [ ! -f /usr/bin/cattools ]; then
            echo "[AD] 你还没有安装 Cattools 以方便安装 LeigodAcc 中依赖部分缺少的组件"
            echo "请查看 https://github.com/miaoermua/cattools 或使用"
            echo "推荐 CatWrt 最新版 https://www.miaoer.net/network/catwrt"
            echo ""
        fi
    fi

    release_info=$(cat /etc/openwrt_release 2>/dev/null)
    if echo "$release_info" | grep -qE "iStoreOS|QWRT|ImmortalWrt|LEDE"; then
        echo "Detected third-party firmware: $(echo "$release_info" | grep -E "iStoreOS|QWRT|ImmortalWrt|LEDE")"
    fi

    pkg_update

    for pkg in libpcap iptables kmod-ipt-nat iptables-mod-tproxy kmod-ipt-ipset ipset; do
        if ! pkg_installed "$pkg"; then
            echo "[INFO] 正在安装必备组件 $pkg"
            pkg_install "$pkg"
        else
            echo "[INFO] $pkg 必备组件已安装，跳过"
        fi
    done

    for pkg in kmod-tun kmod-ipt-tproxy kmod-netem tc-full conntrack; do
        if ! pkg_installed "$pkg"; then
            echo "[INFO] 尝试安装 $pkg"
            pkg_install "$pkg"
        else
            echo "[INFO] $pkg 已安装，跳过"
        fi
    done

    if ! pkg_installed "luci-app-upnp"; then
        echo "[INFO] luci-app-upnp 未安装，正在安装..."
        pkg_install luci-app-upnp
    fi

    if [ -f /etc/config/upnpd ]; then
        echo "[INFO] 正在启用 UPnP..."
        uci set upnpd.config.enabled='1'
        uci commit upnpd

        /etc/init.d/miniupnpd start
        /etc/init.d/miniupnpd enable

        echo "[INFO] UPnP 已启用并运行"
        echo "安装成功后可以在雷神加速器 APP 发现并绑定设备"
        echo
    else
        echo "[ERROR] UPnP 配置不存在，安装可能失败，请检查固件!"
        exit 1
    fi

    echo "[INFO] 下面是雷神官方提供的脚本,打印内容偏长如遇到问题请提供输出内容(截图/文字)反馈到群里."
    
    cd /tmp && sh -c "$(curl -fsSL http://119.3.40.126/router_plugin_new/plugin_install.sh)"

    if [ ! -d /usr/sbin/leigod ]; then
        echo "[ERROR] 检测到 LeigodAcc 未安装，有可能是设备存储空间已满或者雷神服务器挂了!"
        echo "请登录 OpenWrt 路由器后台: 系统-软件包 查看当前可用空间诊断."
    else
        echo "[INFO] LeigodAcc 已成功安装"
    fi

    for pkg in kmod-tun kmod-ipt-tproxy kmod-netem tc-full kmod-ipt-ipset conntrack curl libpcap iptables kmod-ipt-nat iptables-mod-tproxy ipset; do
        if ! pkg_installed "$pkg"; then
            echo "[INFO] 缺少组件包: $pkg"
            echo "[INFO] 你可以通过管理器中的安装依赖性组件进行补充!"
        fi
    done
}

install_compatibility_dependencies() {
    arch=$(pkg_arch)
    if [ -z "$arch" ]; then
        echo "[ERROR] 无法确定系统架构"
        return
    fi

    case "$arch" in
        x86_64)
            packages="tc-full conntrack conntrackd libnetfilter-cttimeout1 libnetfilter-cthelper0"
            urls="https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/x86_64/packages/libnetfilter-cttimeout1_1.0.0-2_x86_64.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/x86_64/packages/libnetfilter-cthelper0_1.0.0-2_x86_64.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/x86_64/base/tc-full_6.3.0-1_x86_64.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/x86_64/packages/conntrackd_1.4.8-1_x86_64.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/x86_64/packages/conntrack_1.4.8-1_x86_64.ipk"
            ;;
        mipsel_24kc)
            packages="tc-full conntrack conntrackd libnetfilter-cttimeout1 libnetfilter-cthelper0"
            urls="https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/mipsel_24kc/packages/conntrackd_1.4.8-1_mips_24kc.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/mipsel_24kc/packages/conntrack_1.4.8-1_mips_24kc.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/mipsel_24kc/packages/libnetfilter-cthelper0_1.0.0-2_mips_24kc.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/mipsel_24kc/packages/libnetfilter-cttimeout1_1.0.0-2_mips_24kc.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/mipsel_24kc/base/tc-full_6.3.0-1_mips_24kc.ipk"
            ;;
        aarch64_cortex-a53|aarch64_cortex-a53+crypto)
            packages="tc-full conntrack conntrackd libnetfilter-cttimeout1 libnetfilter-cthelper0"
            urls="https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/aarch64_cortex-a53/base/tc-full_6.3.0-1_aarch64_cortex-a53.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/aarch64_cortex-a53/packages/conntrack_1.4.8-1_aarch64_cortex-a53.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/aarch64_cortex-a53/packages/conntrackd_1.4.8-1_aarch64_cortex-a53.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/aarch64_cortex-a53/packages/libnetfilter-cttimeout1_1.0.0-2_aarch64_cortex-a53.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/aarch64_cortex-a53/packages/libnetfilter-cthelper0_1.0.0-2_aarch64_cortex-a53.ipk"
            ;;
        aarch64_generic)
            packages="tc-full conntrack conntrackd libnetfilter-cttimeout1 libnetfilter-cthelper0"
            urls="https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/aarch64_generic/packages/conntrack_1.4.8-1_aarch64_generic.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/aarch64_generic/packages/conntrackd_1.4.8-1_aarch64_generic.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/aarch64_generic/packages/libnetfilter-cthelper0_1.0.0-2_aarch64_generic.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/aarch64_generic/packages/libnetfilter-cttimeout1_1.0.0-2_aarch64_generic.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/aarch64_generic/base/tc-full_6.3.0-1_aarch64_generic.ipk"
            ;;
        *)
            echo "[ERROR] 不支持的架构: $arch"
            return
            ;;
    esac

    for pkg in $packages; do
        if ! pkg_installed "$pkg"; then
            echo "[INFO] 安装 $pkg"
            pkg_install "$pkg"
        else
            echo "[INFO] $pkg 已安装，跳过"
        fi
    done

    tmp_dir=$(mktemp -d)
    for pkg in $packages; do
        if ! pkg_installed "$pkg"; then
            if [ "$PKG_MGR" = "opkg" ]; then
                echo "[INFO] $pkg 未在官方源中找到，尝试使用第三方源"
                echo "[INFO] 正在使用天灵 immortalwrt pku 的软件源，并不是原生支持的软件包可能会存在你所在的第三方固件源除外的问题"
                for url in $urls; do
                    wget -P "$tmp_dir" "$url"
                done
                opkg install "$tmp_dir"/*.ipk
            fi
            break
        fi
    done
    rm -rf "$tmp_dir"

    for pkg in kmod-tun kmod-ipt-tproxy kmod-netem tc-full kmod-ipt-ipset conntrack curl libpcap iptables kmod-ipt-nat iptables-mod-tproxy ipset; do
        if ! pkg_installed "$pkg"; then
            echo "[ERROR] 缺少包: $pkg"
            echo "Tip: 你可以到 immortalwrt 官网构建固件并勾选对应的组件替换掉当前系统,或者使用 CatWrt 支持 LeigodAcc 全部依赖."
            echo "https://www.miaoer.net/posts/network/catwrt"
            echo
        fi
    done
}

uninstall_leigodacc() {
    if [ ! -d /usr/sbin/leigod ]; then
        echo "[ERROR] 雷神服务文件不存在，是不是还没安装捏."
        return
    fi

    echo "[INFO] 确定卸载? 输入数字后回车或 10s 后自动卸载 ([1]确定 / [2]取消): "
    read -t 10 choice
    case $choice in
        1)
            ;;
        2)
            return
            ;;
        *)
            ;;
    esac

    if pkg_installed "leigod-acc"; then
        echo "[INFO] leigod-acc 通过 $PKG_MGR 安装，正在卸载"
        /etc/init.d/acc disable 2>/dev/null
        /etc/init.d/acc stop 2>/dev/null
        pkg_remove luci-i18n-leigod-acc-zh-cn luci-app-leigod-acc leigod-acc
        rm -rf /usr/lib/lua/luci/model/cbi/leigod
        rm -rf /usr/lib/lua/luci/view/leigod
        rm -rf /usr/sbin/leigod
        rm -rf /tmp/luci-*
        echo "[INFO] leigod-acc 卸载成功"
    else
        rm /etc/config/accelerator
        /etc/init.d/acc disable
        /etc/init.d/acc stop
        rm /etc/init.d/acc
        rm /usr/lib/lua/luci/controller/acc.lua
        rm -rf /usr/lib/lua/luci/model/cbi/leigod
        rm -rf /usr/lib/lua/luci/view/leigod
        rm -rf /usr/sbin/leigod
        rm /usr/lib/lua/luci/i18n/acc.zh-cn.lmo
        rm -rf /tmp/luci-*
        echo "[INFO] leigod-acc 卸载成功"
    fi
}

reinstall_leigodacc() {
    uninstall_leigodacc
    install_leigodacc
}

service() {
    if [ ! -f /etc/init.d/acc ]; then
        echo "[ERROR] 雷神服务文件不存在，是不是还没安装捏."
        return
    fi

    if /etc/init.d/acc enabled; then
        /etc/init.d/acc disable
        /etc/init.d/acc stop
        echo "[INFO] LeigodAcc 服务已禁用并关闭"
    else
        /etc/init.d/acc enable
        /etc/init.d/acc start
        echo "[INFO] LeigodAcc 服务已启用并启动"
    fi
}

switch_mode() {
    if [ ! -f /etc/init.d/acc ]; then
        echo "[ERROR] 雷神服务文件不存在，是不是还没安装捏."
        return
    fi

    echo "当前版本可能不支持切换模式"
    echo

    if pkg_installed "leigod-acc"; then
        current_tun=$(uci get accelerator.base.tun 2>/dev/null)

        if [ "$current_tun" = "1" ]; then
            uci set accelerator.base.tun='0'
            echo "[INFO] 已切换为 tproxy 模式"
        else
            uci set accelerator.base.tun='1'
            echo "[INFO] 已切换为 tun 模式"
        fi

        uci commit accelerator
    else
        if grep -q -- "--mode tun" /etc/init.d/acc; then
            sed -i 's|--mode tun|${args}|' /etc/init.d/acc
            echo "[INFO] 已切换为 tproxy 模式"
        else
            sed -i 's|${args}|--mode tun|' /etc/init.d/acc
            echo "[INFO] 已切换为 tun 模式"
        fi
    fi
    /etc/init.d/acc stop
    /etc/init.d/acc start
    echo "[INFO] 已经重启 LeigodAcc 服务"
}

disabled_ipv6() {
    config_file="/etc/config/dhcp"
    option_dhcpv6=$(uci get dhcp.lan.dhcpv6)
    option_ra=$(uci get dhcp.lan.ra)

    if [ "$option_dhcpv6" = "disabled" ] && [ "$option_ra" = "disabled" ]; then
        uci set dhcp.lan.ra='server'
        uci set dhcp.lan.dhcpv6='server'
        uci delete dhcp.lan.ra_flags
        uci add_list dhcp.lan.ra_flags='managed-config'
        uci add_list dhcp.lan.ra_flags='other-config'
        echo "[INFO] IPv6 已启用"
        echo "[INFO] 该功能只在 LEDE/QWRT/CatWrt 中测试"
        echo "[INFO] 其他 OpenWrt 版本可能需要在 Luci 界面中启用其他 IPv6 选项以获取正常的 IPv6 网络支持"
    else
        uci delete dhcp.lan.ra_flags
        uci set dhcp.lan.ra='disabled'
        uci set dhcp.lan.dhcpv6='disabled'
        uci add_list dhcp.lan.ra_flags='none'
        echo "[INFO] IPv6 已禁用"
        echo "[INFO] 提示：PC/主机/手机游戏若优先走 IPv6 会导致绕过加速器，禁用后终端设备重新连接网络即可生效"
    fi

    uci commit dhcp
    /etc/init.d/odhcpd restart
}

install_lean_package_version() {
    if pkg_installed "leigod-acc"; then
        echo "[INFO] leigod-acc 已安装"
        return
    else
        echo "[INFO] leigod-acc 未安装"
        pkg_update
    fi

    if [ -d /usr/sbin/leigod ] && ! pkg_installed "leigod-acc"; then
        echo -n "[INFO] 检测到已经安装 LeigodAcc 普通版本，请返回管理器卸载后再继续!"
        return
    fi

    required_packages="libpcap iptables kmod-ipt-nat iptables-mod-tproxy kmod-ipt-tproxy kmod-ipt-ipset ipset kmod-tun curl miniupnpd tc-full kmod-netem conntrack conntrackd luci-compat"
    echo "[INFO] 正在安装必要依赖包..."
    for package in $required_packages; do
        if ! pkg_installed "$package"; then
            echo "[INFO] 尝试安装依赖包: $package"
            pkg_install "$package"
        fi
    done

    arch=$(pkg_arch)

    mkdir -p /tmp/upload
    raw_base="https://raw.githubusercontent.com/Aeko233/leigod-openwrt-installer/main"
    gh_proxy="https://gh-proxy.com"

    if [ "$PKG_MGR" = "apk" ]; then
        echo "[INFO] 检测到 apk 包管理器，准备安装 APK 格式插件..."
        case "$arch" in
            "aarch64_cortex-a53")
                apk_url="$gh_proxy/$raw_base/packages/apk/leigod-acc-1.2.2.52-r1.aarch64_cortex-a53.apk"
                ;;
            "aarch64"|"aarch64_generic")
                apk_url="$gh_proxy/$raw_base/packages/apk/leigod-acc-1.2.2.52-r1.aarch64_generic.apk"
                ;;
            "x86_64")
                apk_url="$gh_proxy/$raw_base/packages/apk/leigod-acc-1.2.2.52-r1.x86_64.apk"
                ;;
            *)
                echo "[ERROR] 不支持的架构: $arch"
                return 1
                ;;
        esac

        echo "[INFO] 正在下载 leigod-acc apk 软件包..."
        wget -P /tmp/upload "$apk_url"
        wget -P /tmp/upload "$gh_proxy/$raw_base/packages/apk/luci-app-leigod-acc-1.3-r1.noarch.apk"
        wget -P /tmp/upload "$gh_proxy/$raw_base/packages/apk/luci-i18n-leigod-acc-zh-cn-1.3-r1.noarch.apk"

        apk add --allow-untrusted /tmp/upload/*.apk
        rm -rf /tmp/upload
    else
        echo "[INFO] 检测到 opkg 包管理器，准备安装 IPK 格式插件..."
        case "$arch" in
            "aarch64_cortex-a53"|"aarch64_cortex-a53+crypto")
                url="https://github.com/miaoermua/openwrt-leigodacc-manager/releases/download/v1.3/leigod-acc_1.3.0.30-1_aarch64_cortex-a53.ipk"
                ;;
            "aarch64_generic")
                url="https://github.com/miaoermua/openwrt-leigodacc-manager/releases/download/v1.3/leigod-acc_1.3.0.30-1_aarch64_generic.ipk"
                ;;
            "mipsel_24kc")
                url="https://github.com/miaoermua/openwrt-leigodacc-manager/releases/download/v1.3/leigod-acc_1.3.0.30-1_mipsel_24kc.ipk"
                ;;
            "x86_64")
                url="https://github.com/miaoermua/openwrt-leigodacc-manager/releases/download/v1.3/leigod-acc_1.3.0.30-1_x86_64.ipk"
                ;;
            *)
                echo "[ERROR] 不支持的架构: $arch"
                return 1
                ;;
        esac

        echo "[INFO] 正在下载 leigod-acc ipk 软件包..."
        wget -P /tmp/upload "$url"
        wget -P /tmp/upload "https://gh-proxy.com/https://github.com/miaoermua/openwrt-leigodacc-manager/releases/download/v1.3/luci-app-leigod-acc_1-3_all.ipk"
        wget -P /tmp/upload "https://gh-proxy.com/https://github.com/miaoermua/openwrt-leigodacc-manager/releases/download/v1.3/luci-i18n-leigod-acc-zh-cn_1-3_all.ipk"

        opkg install /tmp/upload/leigod-acc_*.ipk /tmp/upload/luci-app-leigod-acc_1-3_all.ipk /tmp/upload/luci-i18n-leigod-acc-zh-cn_1-3_all.ipk
        rm -rf /tmp/upload
    fi

    if [ ! -d /usr/sbin/leigod ]; then
        echo "[ERROR] 检测到 LeigodAcc 未安装成功，请检查空间或日志!"
    else
        echo "[INFO] 软件包版 leigod-acc 已成功安装!"
    fi

    if ! pkg_installed "luci-app-upnp"; then
        echo "[INFO] luci-app-upnp 未安装，正在安装..."
        pkg_install luci-app-upnp
    fi

    if [ -f /etc/config/upnpd ]; then
        echo "[INFO] 正在启用 UPnP..."
        uci set upnpd.config.enabled='1'
        uci commit upnpd

        /etc/init.d/miniupnpd start 2>/dev/null
        /etc/init.d/miniupnpd enable 2>/dev/null

        echo "[INFO] UPnP 已启用并运行"
        echo "安装成功后可以在雷神加速器 APP 发现并绑定设备"
        echo
    else
        echo "[ERROR] UPnP 配置不存在，安装可能失败，请检查固件是否存在问题!"
        exit 1
    fi
}

check_logs() {
    if ! pkg_installed "tc-full"; then
        return 0
    fi

    if grep -q "exec tc command failed" /tmp/acc/acc-gw.log-* && grep -q "No such file or directory" /tmp/acc/acc-gw.log-*; then
        echo "[ERROR] 检测到插件中的 tc-full 组件出现了 'exec tc command failed' 错误，可能是软件源或者固件提供的 tc-full 组件问题"
        echo "可能导致无法加速的问题，由于实装 tc-full 的用户过少，请自行测试加速问题或手动重装 tc-full 组件"
        if [ "$PKG_MGR" = "apk" ]; then
            echo "apk update && apk fix tc-full"
        else
            echo "opkg update && opkg remove tc-full && opkg install tc-full"
        fi
        echo
        sleep 5
    fi
}

check_acceleration() {
    log_file="/tmp/acc/acc-gw.log-*.log"

    if [ ! -f "$log_file" ]; then
        return 1
    fi

    if ! grep -q "S5 UDP" "$log_file"; then
        return 1
    fi

    last_s5_udp_time=$(grep -Eo '^[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}' "$log_file" | tail -1)

    if [ -z "$last_s5_udp_time" ]; then
        return 1
    fi

    current_time=$(date +%s)
    log_time=$(date -d "$last_s5_udp_time" +%s)
    time_diff=$((current_time - log_time))

    if [ "$time_diff" -gt 20 ]; then
        echo "[INFO] 检测到 UDP 被成功代理，加速成功"
    fi
}

check_openclash_mode() {
    if ! pgrep -f "openclash" > /dev/null 2>&1; then
        echo "[Tip] 当你 OpenClash 为兼容模式(Tproxy),Leigod 需要切换为 TUN 模式以避免与加速器冲突"
        return 0
    fi

    config_dir="/etc/openclash"
    config_files=$(ls "$config_dir"/*.yaml 2>/dev/null)

    if [ -z "$config_files" ]; then
        return 0
    fi

    for config_file in $config_files; do
        mode=$(grep -E "^mode:" "$config_file" | awk '{print $2}')
        enhanced_mode=$(grep -E "^ *enhanced-mode:" "$config_file" | cut -d':' -f2 | xargs)

        if [ -z "$mode" ] || [ -z "$enhanced_mode" ]; then
            continue
        fi

        if [ "$mode" = "rule" ] && [ "$enhanced_mode" = "redir-host" ];then
            if grep -q "^tun:" "$config_file"; then
                echo "[WARN] 运行模式可能存在冲突!"
                echo "========================="
                echo "OpenClash 运行在 Redir-Host 未处于兼容模式(Tproxy)"
                echo "你需要调整 OpenClash 的运行模式为 ‘兼容’，请移除 TUN 配置以避免 leigod-acc 冲突。"
                echo
                echo "[Tip] 当你 OpenClash 为兼容模式(Tproxy),Leigod 需要切换为 TUN 模式以避免与 Leigod-Acc 冲突!"
            fi
        else
            echo "[WARN] 运行模式冲突!"
            echo "=================="
            echo "检查到 OpenClash 运行在 Fake-IP 未处于 Redir-Host 兼容模式(Tproxy)"
            echo "需要调整 OpenClash 的运行模式为 ‘兼容’，请移除 Fake-IP 配置以避免 leigod-acc 冲突!"
            echo
            echo "OC > 插件设置 > 模式设置 > 切换页面到 Redir-Host 模式"
            echo
            echo "[Tip] 当你 OpenClash 为兼容模式(Tproxy),Leigod 需要切换为 TUN 模式以避免与 Leigod-Acc 冲突!"
            sleep 5
        fi
    done
}

check_bypass_gateway() {
    lan_gateway=$(uci get network.lan.gateway 2>/dev/null)
    lan_ipaddr=$(uci get network.lan.ipaddr 2>/dev/null)
    
    lan_network=$(echo "$lan_ipaddr" | awk -F. '{print $1"."$2"."$3}')
    gateway_network=$(echo "$lan_gateway" | awk -F. '{print $1"."$2"."$3}')

    if [ -n "$lan_gateway" ] && [ "$lan_gateway" != "0.0.0.0" ] && [ "$lan_gateway" != "$lan_ipaddr" ] && [ "$lan_network" = "$gateway_network" ]; then
        echo "[Tip] 检测到旁路网关配置:"
        echo "当前路由器IP: $lan_ipaddr"
        echo "配置的网关: $lan_gateway"
        echo
        echo "注意: 您正在使用旁路网关模式，需要特别注意以下事项:"
        echo "如果是单臂路由(网关不互指):"
        echo "需要在加速设备上配置安装加速器插件的网关&路由器地址"
        echo "如果是双软路由(网关互指):"
        echo "仅需要关闭主路由上的 UPnP 功能"
        echo
        sleep 5
    fi
}

check_openclash_mode
check_acceleration
check_logs
check_bypass_gateway

manage_proxy_bypass() {
    echo
    echo "--- 代理共存设置 (游戏设备绕过科学代理) ---"
    echo "说明：当系统运行 OpenClash/PassWall 等代理插件时，可将游戏设备 IP 加入绕过列表，"
    echo "防火墙将直接放行该设备流量，避免被外部代理拦截或发生规则冲突。"
    echo

    ipset create leigod_bypass hash:ip 2>/dev/null
    
    current_ips=$(ipset list leigod_bypass 2>/dev/null | sed -n '/Members:/,$p' | tail -n +2)
    echo "当前已生效的绕过 IP 列表:"
    if [ -z "$current_ips" ]; then
        echo "  (暂无)"
    else
        for ip in $current_ips; do
            echo "  - $ip"
        done
    fi
    echo
    echo "1. 添加设备 IP 绕过代理"
    echo "2. 移除设备 IP"
    echo "3. 清空所有绕过设备"
    echo "0. 返回上级菜单"
    echo -n "请选择: "
    read -r b_choice

    case $b_choice in
        1)
            echo -n "请输入游戏设备局域网 IP (例如 192.168.1.150): "
            read -r dev_ip
            if [ -n "$dev_ip" ]; then
                ipset create leigod_bypass hash:ip 2>/dev/null
                ipset add leigod_bypass "$dev_ip" 2>/dev/null
                iptables -t mangle -C PREROUTING -m set --match-set leigod_bypass src -j RETURN 2>/dev/null || \
                    iptables -t mangle -I PREROUTING 1 -m set --match-set leigod_bypass src -j RETURN 2>/dev/null
                iptables -t nat -C PREROUTING -m set --match-set leigod_bypass src -j RETURN 2>/dev/null || \
                    iptables -t nat -I PREROUTING 1 -m set --match-set leigod_bypass src -j RETURN 2>/dev/null
                if [ -f /etc/config/openclash ]; then
                    uci add_list openclash.config.bypass_source_ip="$dev_ip" 2>/dev/null
                    uci commit openclash 2>/dev/null
                fi
                echo "[INFO] 已成功添加 $dev_ip 至直连绕过名单，游戏流量将不经过外部代理。"
            fi
            ;;
        2)
            echo -n "请输入要移除的设备 IP: "
            read -r dev_ip
            if [ -n "$dev_ip" ]; then
                ipset del leigod_bypass "$dev_ip" 2>/dev/null
                if [ -f /etc/config/openclash ]; then
                    uci del_list openclash.config.bypass_source_ip="$dev_ip" 2>/dev/null
                    uci commit openclash 2>/dev/null
                fi
                echo "[INFO] 已将 $dev_ip 从绕过名单中移除。"
            fi
            ;;
        3)
            iptables -t mangle -D PREROUTING -m set --match-set leigod_bypass src -j RETURN 2>/dev/null
            iptables -t nat -D PREROUTING -m set --match-set leigod_bypass src -j RETURN 2>/dev/null
            ipset flush leigod_bypass 2>/dev/null
            echo "[INFO] 已清空全部绕过名单。"
            ;;
        *)
            return
            ;;
    esac
}

help() {
    echo ""
    echo "【功能说明】"
    echo "1. 官方脚本安装：直接拉取雷神官方最新加速引擎，适合只需要用手机 App 绑定的用户（路由器后台无网页）。"
    echo "2. 卸载：停止加速进程并清理相关防火墙规则与配置文件。"
    echo "3. 重装/更新：重新下载并部署加速器。"
    echo "4. 启用/停止：控制加速核心是否开机自启和后台运行。"
    echo "5. 切换运行模式：在 TUN 虚拟网卡模式与 Tproxy 透明代理模式之间切换（如使用代理插件请优先选 TUN 模式）。"
    echo "6. 安装网络优化组件：补充 tc-full、conntrack 等包，优化游戏时延与 NAT 类型识别。"
    echo "7. 开关 IPv6：部分 PC/主机/手游在双栈网络下会优先走 IPv6 导致绕过加速代理，若加速异常或无流量可尝试临时关闭局域网 IPv6。"
    echo "8. 安装 LuCI 插件版：安装包含路由器网页管理页面的完整插件（支持新版 apk 与传统 opkg）。"
    echo "9. 代理共存设置：配置游戏主机/PC 的 IP 直连绕过 OpenClash/PassWall 等代理，防止游戏流量被外部代理劫持冲突。"
    echo "10. 查看帮助：显示本说明。"
    echo "0. 退出：退出管理器。"
    echo ""
    sleep 3
}

while true; do
    leigod_menu
    read choice
    case $choice in
        1)
            install_leigodacc
            ;;
        2)
            uninstall_leigodacc
            ;;
        3)
            reinstall_leigodacc
            ;;
        4)
            service
            ;;
        5)
            switch_mode
            ;;
        6)
            install_compatibility_dependencies
            ;;
        7)
            disabled_ipv6
            ;;
        8)
            install_lean_package_version
            ;;
        9)
            manage_proxy_bypass
            ;;
        10)
            help
            ;;
        0)
            exit 0
            ;;
        *)
            echo "[ERROR] 请重新输入对应功能的数字并回车!"
            ;;
    esac
done
