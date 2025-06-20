#!/bin/bash

# 华为云DNS定时更新器 - 更新脚本
# 快速更新到最新版本

set -e

echo "🔄 华为云DNS定时更新器更新工具"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 检查权限
if [ "$EUID" -ne 0 ]; then 
    echo "❌ 请使用 sudo 运行此脚本"
    echo "   sudo ./update.sh"
    echo "   或使用在线更新:"
    echo "   curl -sSL https://raw.githubusercontent.com/yuwan027/HuaweicloudUpdater/main/update.sh | sudo bash"
    exit 1
fi

# 检查是否已安装
INSTALL_DIR="/opt/huaweicloud-dns-updater"
if [ ! -f "$INSTALL_DIR/dns-updater" ]; then
    echo "❌ 未检测到已安装的华为云DNS更新器"
    echo "💡 请先运行安装脚本:"
    echo "   curl -sSL https://raw.githubusercontent.com/yuwan027/HuaweicloudUpdater/main/install.sh | sudo bash"
    exit 1
fi

# 获取当前版本
current_version=$($INSTALL_DIR/dns-updater -version 2>/dev/null | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
if [ -n "$current_version" ]; then
    echo "📦 当前版本: $current_version"
else
    echo "❌ 无法获取当前版本，继续更新..."
fi

# 获取最新版本
echo "🔍 检查最新版本..."
api_url="https://api.github.com/repos/yuwan027/HuaweicloudUpdater/releases/latest"
latest_version=""

if command -v curl >/dev/null 2>&1; then
    latest_version=$(curl -s "$api_url" | grep '"tag_name"' | cut -d'"' -f4)
elif command -v wget >/dev/null 2>&1; then
    latest_version=$(wget -qO- "$api_url" | grep '"tag_name"' | cut -d'"' -f4)
else
    echo "❌ 需要安装 curl 或 wget"
    exit 1
fi

if [ -n "$latest_version" ]; then
    echo "🌐 最新版本: $latest_version"
    
    if [ -n "$current_version" ] && [ "$current_version" = "$latest_version" ]; then
        echo "✅ 当前已是最新版本"
        echo ""
        echo -n "是否强制重新安装? [y/N]: "
        read confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "👋 退出更新"
            exit 0
        fi
    fi
else
    echo "❌ 无法获取最新版本信息"
    echo "💡 请检查网络连接或手动访问: https://github.com/yuwan027/HuaweicloudUpdater/releases"
    exit 1
fi

# 下载并运行更新
echo ""
echo "⬇️  正在下载最新安装脚本..."
temp_script="/tmp/huaweicloud_install_update.sh"

if command -v curl >/dev/null 2>&1; then
    curl -sSL "https://raw.githubusercontent.com/yuwan027/HuaweicloudUpdater/main/install.sh" -o "$temp_script"
elif command -v wget >/dev/null 2>&1; then
    wget -qO "$temp_script" "https://raw.githubusercontent.com/yuwan027/HuaweicloudUpdater/main/install.sh"
fi

if [ ! -f "$temp_script" ]; then
    echo "❌ 下载安装脚本失败"
    exit 1
fi

echo "🚀 开始更新..."
chmod +x "$temp_script"
bash "$temp_script" --update

# 清理临时文件
rm -f "$temp_script"

echo ""
echo "🎉 更新完成！"
echo "💡 使用 'sudo dns-manager' 启动管理工具" 