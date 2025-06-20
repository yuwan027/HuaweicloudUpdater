#!/bin/bash

# 华为云DNS定时更新器 - 自动安装脚本
# 自动下载、安装、配置systemd服务

set -e

VERSION="v1.0.0"
REPO_URL="https://github.com/yuwan027/HuaweicloudUpdater"
RELEASE_URL="$REPO_URL/releases/download/$VERSION"
INSTALL_DIR="/opt/huaweicloud-dns-updater"
BIN_DIR="/usr/local/bin"
CONFIG_DIR="/etc/huaweicloud-dns-updater"
LOG_DIR="/var/log/huaweicloud-dns-updater"
SERVICE_FILE="/etc/systemd/system/huaweicloud-dns-updater.service"

echo "🚀 华为云DNS定时更新器自动安装程序"
echo "📦 版本: $VERSION"
echo "🔗 仓库: $REPO_URL"
echo ""

# 检查权限
if [ "$EUID" -ne 0 ]; then 
    echo "❌ 请使用 sudo 运行此脚本"
    echo "   sudo ./install.sh"
    exit 1
fi

# 检测系统架构和平台
detect_platform() {
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)
    
    case $arch in
        x86_64|amd64)
            arch="amd64"
            ;;
        aarch64|arm64)
            arch="arm64"
            ;;
        i386|i686)
            arch="386"
            ;;
        *)
            echo "❌ 不支持的架构: $arch"
            exit 1
            ;;
    esac
    
    case $os in
        linux)
            platform="linux_$arch"
            binary_name="dns-updater_${VERSION}_linux_$arch"
            ;;
        darwin)
            platform="darwin_$arch"
            binary_name="dns-updater_${VERSION}_darwin_$arch"
            ;;
        *)
            echo "❌ 不支持的操作系统: $os"
            exit 1
            ;;
    esac
    
    echo "🖥️  检测到平台: $os/$arch"
    echo "📁 二进制文件: $binary_name"
}

# 下载二进制文件
download_binary() {
    echo ""
    echo "⬇️  正在下载二进制文件..."
    
    local download_url="$RELEASE_URL/$binary_name"
    local temp_file="/tmp/$binary_name"
    
    echo "🔗 下载地址: $download_url"
    
    if command -v wget >/dev/null 2>&1; then
        wget -q --show-progress -O "$temp_file" "$download_url"
    elif command -v curl >/dev/null 2>&1; then
        curl -L -o "$temp_file" "$download_url" --progress-bar
    else
        echo "❌ 需要安装 wget 或 curl"
        exit 1
    fi
    
    if [ ! -f "$temp_file" ]; then
        echo "❌ 下载失败"
        exit 1
    fi
    
    echo "✅ 下载完成"
    BINARY_FILE="$temp_file"
}

# 创建目录结构
create_directories() {
    echo ""
    echo "📁 创建目录结构..."
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$LOG_DIR"
    
    echo "✅ 目录创建完成"
}

# 安装二进制文件
install_binary() {
    echo ""
    echo "📦 安装二进制文件..."
    
    # 安装主程序
    cp "$BINARY_FILE" "$INSTALL_DIR/dns-updater"
    chmod +x "$INSTALL_DIR/dns-updater"
    
    # 创建软链接到系统PATH
    ln -sf "$INSTALL_DIR/dns-updater" "$BIN_DIR/dns-updater"
    
    # 清理临时文件
    rm -f "$BINARY_FILE"
    
    echo "✅ 二进制文件安装完成"
}

# 创建配置文件
create_config() {
    echo ""
    echo "⚙️  创建配置文件..."
    
    cat > "$CONFIG_DIR/config.yaml" << 'EOF'
# 华为云DNS定时更新配置文件
huaweicloud:
  # 华为云访问密钥（请替换为您的实际密钥）
  access_key: "YOUR_ACCESS_KEY"
  secret_key: "YOUR_SECRET_KEY"
  # 华为云区域
  region: "cn-north-4"

# 域名配置列表
domains: []
  # 示例配置（取消注释并修改）:
  # - name: "example.com"
  #   zone_id: "your_zone_id"
  #   original_ip: "1.1.1.1"
  #   target_ip: "2.2.2.2"
  #   record_type: "A"
  #   ttl: 300

# 定时任务配置
schedule:
  # 切换到目标IP的时间（cron表达式格式）
  switch_to_target: "0 2 * * *"     # 每天凌晨2点
  
  # 恢复到原始IP的时间（可选）
  restore_to_original: "0 8 * * *"  # 每天早上8点

# 日志配置
logging:
  level: "info"
  file: "/var/log/huaweicloud-dns-updater/dns_updater.log"
EOF

    chmod 644 "$CONFIG_DIR/config.yaml"
    echo "✅ 配置文件创建完成: $CONFIG_DIR/config.yaml"
}

# 创建systemd服务
create_systemd_service() {
    echo ""
    echo "🔧 创建systemd服务..."
    
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=华为云DNS定时更新器
Documentation=https://github.com/yuwan027/HuaweicloudUpdater
After=network.target network-online.target
Requires=network-online.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/dns-updater -config $CONFIG_DIR/config.yaml
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=huaweicloud-dns-updater
KillMode=mixed
KillSignal=SIGTERM

# 安全设置
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$LOG_DIR $CONFIG_DIR

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    echo "✅ systemd服务创建完成"
}

# 创建管理脚本
create_manager_script() {
    echo ""
    echo "🛠️  创建管理脚本..."
    
    cat > "$BIN_DIR/dns-manager" << 'EOF'
#!/bin/bash

# 华为云DNS更新器管理脚本

CONFIG_FILE="/etc/huaweicloud-dns-updater/config.yaml"
LOG_FILE="/var/log/huaweicloud-dns-updater/dns_updater.log"
SERVICE_NAME="huaweicloud-dns-updater"

show_menu() {
    echo ""
    echo "🔧 华为云DNS更新器管理工具"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "1️⃣  查看当前域名配置列表"
    echo "2️⃣  增加域名配置"
    echo "3️⃣  删除域名配置"
    echo "4️⃣  查看服务状态"
    echo "5️⃣  查看日志"
    echo "6️⃣  清空日志"
    echo "7️⃣  重启服务"
    echo "8️⃣  编辑配置文件"
    echo "9️⃣  测试配置"
    echo "0️⃣  退出"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -n "请选择操作 [0-9]: "
}

show_domains() {
    echo ""
    echo "📋 当前域名配置列表:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if ! command -v yq >/dev/null 2>&1; then
        echo "⚠️  需要安装 yq 来解析YAML文件"
        echo "   Ubuntu/Debian: sudo apt install yq"
        echo "   CentOS/RHEL: sudo yum install yq"
        echo ""
        echo "临时查看配置:"
        grep -A 20 "domains:" "$CONFIG_FILE" | head -20
        return
    fi
    
    local count=$(yq '.domains | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
    
    if [ "$count" -eq 0 ]; then
        echo "📭 暂无域名配置"
    else
        echo "共 $count 个域名配置:"
        echo ""
        for i in $(seq 0 $((count-1))); do
            local name=$(yq ".domains[$i].name" "$CONFIG_FILE" 2>/dev/null)
            local zone_id=$(yq ".domains[$i].zone_id" "$CONFIG_FILE" 2>/dev/null)
            local original_ip=$(yq ".domains[$i].original_ip" "$CONFIG_FILE" 2>/dev/null)
            local target_ip=$(yq ".domains[$i].target_ip" "$CONFIG_FILE" 2>/dev/null)
            local record_type=$(yq ".domains[$i].record_type" "$CONFIG_FILE" 2>/dev/null)
            local ttl=$(yq ".domains[$i].ttl" "$CONFIG_FILE" 2>/dev/null)
            
            echo "[$((i+1))] 域名: $name"
            echo "    Zone ID: $zone_id"
            echo "    原始IP: $original_ip"
            echo "    目标IP: $target_ip"
            echo "    记录类型: $record_type"
            echo "    TTL: $ttl"
            echo ""
        done
    fi
}

add_domain() {
    echo ""
    echo "➕ 添加域名配置"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    echo -n "请输入域名 (如: example.com): "
    read domain_name
    
    echo -n "请输入Zone ID: "
    read zone_id
    
    echo -n "请输入原始IP地址: "
    read original_ip
    
    echo -n "请输入目标IP地址: "
    read target_ip
    
    echo -n "请输入记录类型 [A]: "
    read record_type
    record_type=${record_type:-A}
    
    echo -n "请输入TTL [300]: "
    read ttl
    ttl=${ttl:-300}
    
    echo ""
    echo "📝 确认添加以下配置:"
    echo "   域名: $domain_name"
    echo "   Zone ID: $zone_id"
    echo "   原始IP: $original_ip"
    echo "   目标IP: $target_ip"
    echo "   记录类型: $record_type"
    echo "   TTL: $ttl"
    echo ""
    echo -n "确认添加? [y/N]: "
    read confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # 备份配置文件
        cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        
        # 添加新配置
        if command -v yq >/dev/null 2>&1; then
            yq -i ".domains += [{\"name\": \"$domain_name\", \"zone_id\": \"$zone_id\", \"original_ip\": \"$original_ip\", \"target_ip\": \"$target_ip\", \"record_type\": \"$record_type\", \"ttl\": $ttl}]" "$CONFIG_FILE"
            echo "✅ 域名配置添加成功"
        else
            echo "❌ 需要安装 yq 才能自动添加配置"
            echo "请手动编辑配置文件: $CONFIG_FILE"
        fi
    else
        echo "❌ 取消添加"
    fi
}

delete_domain() {
    echo ""
    echo "🗑️  删除域名配置"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if ! command -v yq >/dev/null 2>&1; then
        echo "❌ 需要安装 yq 才能删除配置"
        return
    fi
    
    local count=$(yq '.domains | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
    
    if [ "$count" -eq 0 ]; then
        echo "📭 暂无域名配置可删除"
        return
    fi
    
    echo "当前域名列表:"
    for i in $(seq 0 $((count-1))); do
        local name=$(yq ".domains[$i].name" "$CONFIG_FILE" 2>/dev/null)
        echo "[$((i+1))] $name"
    done
    
    echo ""
    echo -n "请输入要删除的域名编号 [1-$count]: "
    read index
    
    if [[ "$index" =~ ^[0-9]+$ ]] && [ "$index" -ge 1 ] && [ "$index" -le "$count" ]; then
        local name=$(yq ".domains[$((index-1))].name" "$CONFIG_FILE" 2>/dev/null)
        echo ""
        echo -n "确认删除域名 '$name'? [y/N]: "
        read confirm
        
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            # 备份配置文件
            cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
            
            # 删除配置
            yq -i "del(.domains[$((index-1))])" "$CONFIG_FILE"
            echo "✅ 域名配置删除成功"
        else
            echo "❌ 取消删除"
        fi
    else
        echo "❌ 无效的编号"
    fi
}

show_status() {
    echo ""
    echo "📊 服务状态"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    systemctl status "$SERVICE_NAME" --no-pager
}

show_logs() {
    echo ""
    echo "📄 查看日志"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "1) 查看实时日志"
    echo "2) 查看最近50行日志"
    echo "3) 查看今天的日志"
    echo ""
    echo -n "请选择 [1-3]: "
    read choice
    
    case $choice in
        1)
            echo "按 Ctrl+C 退出实时日志查看"
            journalctl -u "$SERVICE_NAME" -f
            ;;
        2)
            journalctl -u "$SERVICE_NAME" -n 50 --no-pager
            ;;
        3)
            journalctl -u "$SERVICE_NAME" --since today --no-pager
            ;;
        *)
            echo "❌ 无效选择"
            ;;
    esac
}

clear_logs() {
    echo ""
    echo "🗑️  清空日志"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -n "确认清空所有日志? [y/N]: "
    read confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        journalctl --vacuum-time=1s --quiet
        if [ -f "$LOG_FILE" ]; then
            > "$LOG_FILE"
        fi
        echo "✅ 日志已清空"
    else
        echo "❌ 取消清空"
    fi
}

restart_service() {
    echo ""
    echo "🔄 重启服务"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    systemctl restart "$SERVICE_NAME"
    echo "✅ 服务重启完成"
    sleep 2
    systemctl status "$SERVICE_NAME" --no-pager
}

edit_config() {
    echo ""
    echo "✏️  编辑配置文件"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if command -v nano >/dev/null 2>&1; then
        nano "$CONFIG_FILE"
    elif command -v vim >/dev/null 2>&1; then
        vim "$CONFIG_FILE"
    else
        echo "❌ 未找到文本编辑器 (nano/vim)"
    fi
}

test_config() {
    echo ""
    echo "🧪 测试配置"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    dns-updater -config "$CONFIG_FILE" -test
}

main() {
    if [ "$EUID" -ne 0 ]; then 
        echo "❌ 请使用 sudo 运行此脚本"
        exit 1
    fi
    
    while true; do
        show_menu
        read choice
        
        case $choice in
            1) show_domains ;;
            2) add_domain ;;
            3) delete_domain ;;
            4) show_status ;;
            5) show_logs ;;
            6) clear_logs ;;
            7) restart_service ;;
            8) edit_config ;;
            9) test_config ;;
            0) echo "👋 再见!"; exit 0 ;;
            *) echo "❌ 无效选择，请重新输入" ;;
        esac
        
        echo ""
        echo -n "按 Enter 继续..."
        read
    done
}

main "$@"
EOF

    chmod +x "$BIN_DIR/dns-manager"
    echo "✅ 管理脚本创建完成: $BIN_DIR/dns-manager"
}

# 主安装流程
main() {
    detect_platform
    download_binary
    create_directories
    install_binary
    create_config
    create_systemd_service
    create_manager_script
    
    echo ""
    echo "🎉 安装完成!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📍 安装位置:"
    echo "   程序目录: $INSTALL_DIR"
    echo "   配置目录: $CONFIG_DIR"
    echo "   日志目录: $LOG_DIR"
    echo ""
    echo "🔧 下一步操作:"
    echo "   1. 编辑配置文件: sudo nano $CONFIG_DIR/config.yaml"
    echo "   2. 配置华为云 AK/SK 和域名信息"
    echo "   3. 启动服务: sudo systemctl enable --now $SERVICE_NAME"
    echo "   4. 使用管理工具: sudo dns-manager"
    echo ""
    echo "📚 常用命令:"
    echo "   sudo systemctl status huaweicloud-dns-updater  # 查看服务状态"
    echo "   sudo dns-manager                               # 启动管理工具"
    echo "   dns-updater -version                           # 查看版本"
    echo ""
    echo "🔗 项目地址: $REPO_URL"
}

main "$@" 