#!/bin/bash

# =============================================================================
# Kangle 安装脚本适配 CentOS 6、7-8 / Stream 8
# =============================================================================

set -e  # 在出现错误时立即退出脚本

# =============================================================================
# 配置参数
# =============================================================================

VERSION="3.5.21.16"
DSOVERSION="3.5.21.12"

# =============================================================================
# 检查输入参数
# =============================================================================

if [ $# -ne 1 ]; then
    echo "Usage: $0 <install_directory>"
    exit 1
fi

PREFIX=$1

# =============================================================================
# 检查是否为 root 用户
# =============================================================================

if [ "$(id -u)" -ne 0 ]; then
    echo "此脚本需要以 root 用户身份运行。"
    exit 1
fi

# =============================================================================
# 检测操作系统类型和版本
# =============================================================================

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION_ID=${VERSION_ID%%.*}
else
    echo "无法检测操作系统类型。"
    exit 1
fi

if [[ "$OS" != "centos" ]]; then
    echo "此脚本仅适用于 CentOS 6、7-8 / Stream 8。"
    exit 1
fi

# =============================================================================
# 确定 CentOS 版本
# =============================================================================

if [[ "$VERSION_ID" == "6" ]]; then
    CENTOS_VERSION=6
elif [[ "$VERSION_ID" == "7" || "$VERSION_ID" == "8" ]]; then
    CENTOS_VERSION=$VERSION_ID
elif [[ "$VERSION_ID" == "Stream" ]]; then
    CENTOS_VERSION="8"
else
    echo "不支持的 CentOS 版本: $VERSION_ID"
    exit 1
fi

echo "检测到的 CentOS 版本: $CENTOS_VERSION"

# =============================================================================
# 确定包管理器
# =============================================================================

if [[ "$CENTOS_VERSION" -ge 8 ]]; then
    if command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
    else
        PKG_MANAGER="yum"
    fi
else
    PKG_MANAGER="yum"
fi

echo "使用的包管理器: $PKG_MANAGER"

# =============================================================================
# 设置 ARCH 变量
# =============================================================================

ARCH="-$CENTOS_VERSION"

if [ "$(arch)" = "x86_64" ]; then
    ARCH="${ARCH}-x64"
fi

echo "检测到的 ARCH: $ARCH"

# =============================================================================
# 停止并禁用 httpd 和 nginx 服务
# =============================================================================

echo "停止并禁用 httpd 和 nginx 服务..."

SERVICES=("httpd" "nginx")

for svc in "${SERVICES[@]}"; do
    if [[ "$CENTOS_VERSION" -ge 7 ]]; then
        if systemctl list-units --type=service --all | grep -q "$svc"; then
            sudo systemctl stop "$svc" || true
            sudo systemctl disable "$svc" || true
            echo "$svc 服务已停止并禁用。"
        else
            echo "$svc 服务不存在或已停止。"
        fi
    else
        if service "$svc" status >/dev/null 2>&1; then
            sudo service "$svc" stop || true
            sudo chkconfig --level 2345 "$svc" off || true
            echo "$svc 服务已停止并禁用。"
        else
            echo "$svc 服务不存在或已停止。"
        fi
    fi
done

# =============================================================================
# 安装必要的软件包
# =============================================================================

echo "安装必要的软件包..."

# 更新包管理器
sudo $PKG_MANAGER -y update

# 安装软件包
sudo $PKG_MANAGER -y install libjpeg-turbo libtiff libpng unzip wget iptables-services

# 启用并启动 iptables 服务
sudo systemctl start iptables
sudo systemctl enable iptables

# =============================================================================
# 配置防火墙
# =============================================================================

echo "配置防火墙..."

PORTS=(80 443 3311 3312 3313 21)

# 检查操作系统版本并配置防火墙规则
if [[ "$CENTOS_VERSION" -ge 7 ]]; then
    # CentOS 7 和更高版本默认使用 firewalld，我们需要先停用 firewalld
    echo "检测到 CentOS 7 或更高版本，正在停用 firewalld..."

    # 停用并禁用 firewalld
    sudo systemctl stop firewalld
    sudo systemctl disable firewalld

    # 安装并启用 iptables
    sudo yum install -y iptables-services
    sudo systemctl start iptables
    sudo systemctl enable iptables
    echo "已成功停用 firewalld 并启用 iptables。"
fi

# 配置 iptables 防火墙规则
for port in "${PORTS[@]}"; do
    sudo /sbin/iptables -I INPUT -p tcp --dport "$port" -j ACCEPT
done

# 保存 iptables 配置
sudo service iptables save
# 重启 iptables 服务以应用规则
sudo systemctl restart iptables

echo "防火墙端口已开放（通过 iptables）。"

# =============================================================================
# 安装 Kangle
# =============================================================================

echo "安装 Kangle..."

KANGLE_TAR="kangle-ent-${VERSION}${ARCH}.tar.gz"
KANGLE_URL="https://github.com/gzwillyy/kangle/raw/master/ent/${KANGLE_TAR}"

# 打印出实际的下载 URL，确认它正确
echo "下载 Kangle 安装包: $KANGLE_URL"

# # 下载 Kangle 安装包
# if ! wget "$KANGLE_URL" -O "$KANGLE_TAR"; then
#     echo "下载 Kangle 安装包失败"
#     exit 1
# fi
# echo "已下载 Kangle 安装包。"

# tar xzf "$KANGLE_TAR"
# cd kangle || { echo "解压 Kangle 安装包失败。"; exit 1; }

# # 停止已有的 Kangle 实例
# echo "停止已有的 Kangle 实例（如果有）..."
# sudo $PREFIX/bin/kangle -q || true
# sudo killall -9 kangle || true
# sleep 3

# mkdir -p "$PREFIX"

# # 下载许可文件
# LICENSE_URL="https://github.com/gzwillyy/kangle/raw/master/ent/license/Ultimate/license.txt"
# if ! wget "$LICENSE_URL" -O "$PREFIX/license.txt"; then
#     echo "下载许可文件失败"
#     exit 1
# fi
# echo "已下载许可文件。"

# # 运行安装脚本
# echo "运行 Kangle 安装脚本..."
# sudo ./install.sh "$PREFIX"
# echo "Kangle 安装脚本已运行。"

# # 启动 Kangle
# echo "启动 Kangle..."
# if ! sudo $PREFIX/bin/kangle; then
#     echo "启动 Kangle 失败，请检查权限或日志。"
#     exit 1
# fi

# # =============================================================================
# # 配置开机自启
# # =============================================================================

# echo "配置开机自启..."

# if [[ "$CENTOS_VERSION" -eq 6 ]]; then
#     echo "$PREFIX/bin/kangle" | sudo tee -a /etc/rc.d/rc.local
#     sudo chmod +x /etc/rc.d/rc.local
#     echo "已将 Kangle 添加到 /etc/rc.d/rc.local 以实现开机自启。"
# elif [[ "$CENTOS_VERSION" -ge 7 ]]; then
#     KANGLE_SERVICE_FILE="/etc/systemd/system/kangle.service"

#     if [ ! -f "$KANGLE_SERVICE_FILE" ]; then
#         sudo bash -c "cat > $KANGLE_SERVICE_FILE" <<EOL
# [Unit]
# Description=Kangle Web Server
# After=network.target

# [Service]
# Type=simple
# ExecStart=$PREFIX/bin/kangle
# Restart=on-failure

# [Install]
# WantedBy=multi-user.target
# EOL
#         sudo systemctl daemon-reload
#         sudo systemctl enable kangle
#         sudo systemctl start kangle
#         echo "已创建并启用 systemd 服务文件 kangle.service。"
#     else
#         echo "systemd 服务文件 kangle.service 已存在。"
#     fi
# fi

# # =============================================================================
# # 更新首页
# # =============================================================================

# echo "更新 Kangle 首页..."

# sudo rm -rf "$PREFIX/www/index.html"
# EASY_PANEL_URL="https://github.com/gzwillyy/kangle/raw/master/easypanel/index.html"
# if ! wget "$EASY_PANEL_URL" -O "$PREFIX/www/index.html"; then
#     echo "更新首页失败"
#     exit 1
# fi
# echo "首页已更新。"

# # 重启 Kangle 以应用更改
# echo "重启 Kangle 以应用更改..."
# sudo $PREFIX/bin/kangle -q
# sudo $PREFIX/bin/kangle -z /var/cache/kangle

# cd ..

# # =============================================================================
# # 安装 DSO
# # =============================================================================

# echo "安装 DSO..."

# DSO_ZIP="kangle-dso-${DSOVERSION}.zip"
# DSO_URL="https://github.com/gzwillyy/kangle/raw/master/dso/${DSO_ZIP}"

# if ! wget "$DSO_URL" -O "$DSO_ZIP"; then
#     echo "下载 DSO 包失败"
#     exit 1
# fi
# echo "已下载 DSO 包。"

# unzip -o "$DSO_ZIP"
# echo "已解压 DSO 包。"

# cd dso || { echo "进入 dso 目录失败。"; exit 1; }

# sudo cp -rf bin "$PREFIX"
# sudo cp -rf ext "$PREFIX"

# # 启动 Kangle 以应用 DSO 更改
# echo "启动 Kangle 以应用 DSO 更改..."
# sudo $PREFIX/bin/kangle

# cd ..

# # =============================================================================
# # 完成安装
# # =============================================================================

# echo "Kangle 安装完成。"
