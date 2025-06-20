# 华为云DNS定时更新器

这是一个基于华为云DNS API的定时域名解析更新工具，支持多域名批量管理，可以定时切换域名解析到不同的IP地址。

## 功能特性

- ✅ 支持多域名批量管理
- ✅ 基于Cron表达式的灵活定时任务
- ✅ 支持IP地址的定时切换和恢复
- ✅ 完整的错误处理和日志记录
- ✅ 支持手动立即执行切换/恢复操作
- ✅ 配置文件验证和DNS连接测试
- ✅ 优雅的服务启停
- ✅ **自动安装脚本** - 一键安装和配置
- ✅ **systemd服务保活** - 自动重启和开机启动
- ✅ **图形化管理工具** - 友好的交互式管理界面
- ✅ **跨平台支持** - 支持14个平台和架构

## 快速开始 (推荐)

### 🚀 一键自动安装

```bash
# 下载并运行安装脚本
curl -fsSL https://raw.githubusercontent.com/yuwan027/HuaweicloudUpdater/main/install.sh | sudo bash

# 或者手动下载安装
wget https://raw.githubusercontent.com/yuwan027/HuaweicloudUpdater/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

安装完成后：

1. **配置华为云密钥**：
   ```bash
   sudo nano /etc/huaweicloud-dns-updater/config.yaml
   ```

2. **启动服务**：
   ```bash
   sudo systemctl enable --now huaweicloud-dns-updater
   ```

3. **使用管理工具**：
   ```bash
   sudo dns-manager
   ```

### 📱 管理工具界面

运行 `sudo dns-manager` 后会看到：

```
🔧 华为云DNS更新器管理工具
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1️⃣  查看当前域名配置列表
2️⃣  增加域名配置
3️⃣  删除域名配置
4️⃣  查看服务状态
5️⃣  查看日志
6️⃣  清空日志
7️⃣  重启服务
8️⃣  编辑配置文件
9️⃣  测试配置
0️⃣  退出
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
请选择操作 [0-9]:
```

## 跨平台支持

### 📦 预编译版本下载

从 [GitHub Releases](https://github.com/yuwan027/HuaweicloudUpdater/releases/tag/v1.0.0) 下载适合您系统的预编译版本：

#### Linux 系统：
- **Linux x64**: `dns-updater_v1.0.0_linux_amd64`
- **Linux ARM64**: `dns-updater_v1.0.0_linux_arm64`
- **Linux x86**: `dns-updater_v1.0.0_linux_386`

#### Windows 系统：
- **Windows x64**: `dns-updater_v1.0.0_windows_amd64.exe`
- **Windows ARM64**: `dns-updater_v1.0.0_windows_arm64.exe`
- **Windows x86**: `dns-updater_v1.0.0_windows_386.exe`

#### macOS 系统：
- **macOS Intel**: `dns-updater_v1.0.0_darwin_amd64`
- **macOS ARM (M系列芯片)**: `dns-updater_v1.0.0_darwin_arm64`

#### BSD 系统：
- **FreeBSD x64/ARM64**: `dns-updater_v1.0.0_freebsd_amd64/arm64`
- **OpenBSD x64/ARM64**: `dns-updater_v1.0.0_openbsd_amd64/arm64`
- **NetBSD x64/ARM64**: `dns-updater_v1.0.0_netbsd_amd64/arm64`

### 🔨 从源码编译

#### 单平台编译：
```bash
# 设置优化环境变量（国内用户推荐）
export GOPROXY=https://mirrors.aliyun.com/goproxy/,direct
export GOMAXPROCS=$(nproc)  # Linux
export GOMAXPROCS=$(sysctl -n hw.ncpu)  # macOS

# 下载依赖
go mod tidy

# 编译程序
go build -o dns-updater -ldflags="-s -w" .
```

#### 跨平台编译（M4芯片优化）：
```bash
# 执行跨平台编译脚本
chmod +x build-cross.sh
./build-cross.sh

# 将在 releases/ 目录生成所有平台的二进制文件
```

## 手动安装与配置

### 1. 环境要求

- Go 1.21 或更高版本（仅从源码编译时需要）
- 华为云账号和有效的访问密钥(AK/SK)
- 已配置的DNS私有域名
- Linux系统（推荐Ubuntu 20.04+或CentOS 8+）

### 2. 手动部署

```bash
# 1. 下载二进制文件
wget https://github.com/yuwan027/HuaweicloudUpdater/releases/download/v1.0.0/dns-updater_v1.0.0_linux_amd64
chmod +x dns-updater_v1.0.0_linux_amd64

# 2. 创建目录结构
sudo mkdir -p /opt/huaweicloud-dns-updater
sudo mkdir -p /etc/huaweicloud-dns-updater
sudo mkdir -p /var/log/huaweicloud-dns-updater

# 3. 安装程序
sudo cp dns-updater_v1.0.0_linux_amd64 /opt/huaweicloud-dns-updater/dns-updater
sudo ln -sf /opt/huaweicloud-dns-updater/dns-updater /usr/local/bin/dns-updater
```

### 3. 配置文件

创建 `/etc/huaweicloud-dns-updater/config.yaml` 并根据实际情况修改配置：

```yaml
# 华为云DNS定时更新配置文件
huaweicloud:
  # 华为云访问密钥
  access_key: "YOUR_ACCESS_KEY"
  secret_key: "YOUR_SECRET_KEY"
  # 华为云区域
  region: "cn-north-4"

# 域名配置列表
domains:
  - name: "example1.com"
    zone_id: "your_zone_id_1"
    original_ip: "1.1.1.1"
    target_ip: "2.2.2.2"
    record_type: "A"
    ttl: 300
    
  - name: "example2.com"
    zone_id: "your_zone_id_2"
    original_ip: "3.3.3.3"
    target_ip: "4.4.4.4"
    record_type: "A"
    ttl: 300

# 定时任务配置
schedule:
  # 切换到目标IP的时间（cron表达式）
  switch_to_target: "0 2 * * *"     # 每天凌晨2点
  
  # 恢复到原始IP的时间（可选）
  restore_to_original: "0 8 * * *"  # 每天早上8点

# 日志配置
logging:
  level: "info"
  file: "dns_updater.log"
```

### 4. 获取华为云配置信息

#### 获取访问密钥 (AK/SK)
1. 登录华为云控制台
2. 进入 "我的凭证" > "访问密钥"
3. 创建新的访问密钥或使用现有的

#### 获取Zone ID
1. 登录华为云DNS控制台
2. 进入 "云解析服务" > "私网解析"
3. 找到对应的域名，Zone ID 显示在列表中

### 4. 创建systemd服务

```bash
# 创建服务文件
sudo tee /etc/systemd/system/huaweicloud-dns-updater.service > /dev/null <<EOF
[Unit]
Description=华为云DNS定时更新器
Documentation=https://github.com/yuwan027/HuaweicloudUpdater
After=network.target network-online.target
Requires=network-online.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/huaweicloud-dns-updater
ExecStart=/opt/huaweicloud-dns-updater/dns-updater -config /etc/huaweicloud-dns-updater/config.yaml
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
ReadWritePaths=/var/log/huaweicloud-dns-updater /etc/huaweicloud-dns-updater

[Install]
WantedBy=multi-user.target
EOF

# 重载systemd并启动服务
sudo systemctl daemon-reload
sudo systemctl enable --now huaweicloud-dns-updater
```

## 使用方法

### 🎮 图形化管理（推荐）

安装完成后，使用图形化管理工具：

```bash
sudo dns-manager
```

功能包括：
- 📋 查看当前域名配置列表（格式化输出）
- ➕ 增加域名配置（交互式输入）
- 🗑️ 删除域名配置（安全确认）
- 📊 查看服务状态
- 📄 查看日志（实时/历史）
- 🧹 清空日志
- 🔄 重启服务
- ✏️ 编辑配置文件
- 🧪 测试配置

### 📋 systemd服务管理

```bash
# 查看服务状态
sudo systemctl status huaweicloud-dns-updater

# 启动/停止/重启服务
sudo systemctl start huaweicloud-dns-updater
sudo systemctl stop huaweicloud-dns-updater
sudo systemctl restart huaweicloud-dns-updater

# 开机自启/禁用自启
sudo systemctl enable huaweicloud-dns-updater
sudo systemctl disable huaweicloud-dns-updater

# 查看日志
sudo journalctl -u huaweicloud-dns-updater -f        # 实时日志
sudo journalctl -u huaweicloud-dns-updater -n 50     # 最近50行
sudo journalctl -u huaweicloud-dns-updater --since today  # 今天的日志
```

### 💻 命令行用法

```bash
# 测试配置文件
dns-updater -test

# 显示版本信息
dns-updater -version

# 立即切换到目标IP
dns-updater -config /etc/huaweicloud-dns-updater/config.yaml -switch

# 立即恢复到原始IP
dns-updater -config /etc/huaweicloud-dns-updater/config.yaml -restore

# 查看定时任务信息
dns-updater -config /etc/huaweicloud-dns-updater/config.yaml -list
```

### 🔧 配置文件管理

```bash
# 编辑配置文件
sudo nano /etc/huaweicloud-dns-updater/config.yaml

# 验证配置文件语法
dns-updater -config /etc/huaweicloud-dns-updater/config.yaml -test

# 备份配置文件
sudo cp /etc/huaweicloud-dns-updater/config.yaml /etc/huaweicloud-dns-updater/config.yaml.backup
```

## Cron表达式说明

本程序支持标准的Cron表达式格式：

```
秒 分 时 日 月 星期
*  *  *  *  *  *
```

### 示例：

- `"0 2 * * *"` - 每天凌晨2点执行
- `"0 */6 * * *"` - 每6小时执行一次
- `"0 0 1 * *"` - 每月1号执行
- `"0 0 * * 1"` - 每周一执行
- `"30 14 * * 1-5"` - 工作日下午2:30执行

## 日志说明

程序会记录以下信息：
- 服务启动/停止状态
- DNS记录查询和更新操作
- 定时任务执行日志
- 错误和异常信息

日志级别：
- `debug` - 调试信息
- `info` - 常规信息（推荐）
- `warn` - 警告信息
- `error` - 错误信息

## 🔧 开发者相关

### M4芯片优化编译

针对苹果M4芯片的性能优化编译：

```bash
# 设置M4芯片优化环境
export GOPROXY=https://mirrors.aliyun.com/goproxy/,direct
export GOMAXPROCS=$(sysctl -n hw.ncpu)  # 充分利用M4的10核心
export CGO_ENABLED=0

# 高性能编译
time go build -o dns-updater -ldflags="-s -w" -gcflags="-N -l" .

# 跨平台批量编译
./build-cross.sh  # 并行编译14个平台，充分压榨M4性能
```

### 项目结构

```
HuaweicloudUpdater/
├── main.go              # 主程序入口
├── config.go            # 配置文件处理
├── dns_client.go        # 华为云DNS API客户端
├── scheduler.go         # 定时任务调度器
├── config.yaml          # 配置文件模板
├── install.sh           # 自动安装脚本
├── build-cross.sh       # 跨平台编译脚本
├── go.mod               # Go模块文件
└── README.md            # 项目文档
```

## ❓ 常见问题

### 1. 🔐 认证失败
- **问题**：`创建DNS客户端失败` 或 `认证失败`
- **解决**：
  ```bash
  # 检查AK/SK是否正确
  sudo dns-manager  # 选择 "8️⃣ 编辑配置文件"
  
  # 验证配置
  dns-updater -test
  ```

### 2. 🌐 Zone ID 无效
- **问题**：`无法访问Zone ID` 或 `Zone不存在`
- **解决**：
  1. 登录华为云DNS控制台
  2. 进入 "云解析服务" > "私网解析"
  3. 复制正确的Zone ID

### 3. 📝 记录不存在
- **问题**：`未找到记录` 或 `记录不存在`
- **解决**：程序会自动创建不存在的DNS记录，确保域名名称格式正确

### 4. ⏰ 定时任务不执行
- **问题**：定时任务配置后没有执行
- **解决**：
  ```bash
  # 检查Cron表达式
  dns-updater -list
  
  # 查看服务状态
  sudo systemctl status huaweicloud-dns-updater
  
  # 查看日志
  sudo journalctl -u huaweicloud-dns-updater -f
  ```

### 5. 🚫 权限问题
- **问题**：`Permission denied` 或访问被拒绝
- **解决**：确保使用 `sudo` 运行需要管理员权限的命令

### 6. 📦 依赖缺失
- **问题**：管理工具中部分功能不可用
- **解决**：
  ```bash
  # Ubuntu/Debian
  sudo apt update && sudo apt install yq nano

  # CentOS/RHEL
  sudo yum install yq nano
  
  # macOS
  brew install yq nano
  ```

## 🗑️ 卸载程序

### 完全卸载

```bash
# 停止并禁用服务
sudo systemctl stop huaweicloud-dns-updater
sudo systemctl disable huaweicloud-dns-updater

# 删除服务文件
sudo rm -f /etc/systemd/system/huaweicloud-dns-updater.service
sudo systemctl daemon-reload

# 删除程序文件
sudo rm -rf /opt/huaweicloud-dns-updater
sudo rm -f /usr/local/bin/dns-updater
sudo rm -f /usr/local/bin/dns-manager

# 删除配置和日志（可选）
sudo rm -rf /etc/huaweicloud-dns-updater
sudo rm -rf /var/log/huaweicloud-dns-updater

# 清理日志
sudo journalctl --vacuum-time=1s
```

## 📊 性能监控

### 资源使用情况

```bash
# 查看内存和CPU使用
ps aux | grep dns-updater

# 查看服务详细状态
sudo systemctl status huaweicloud-dns-updater

# 监控日志大小
du -sh /var/log/huaweicloud-dns-updater/
```

### 服务健康检查

```bash
# 服务自检
dns-updater -test

# 网络连通性检查
ping iam.cn-north-4.myhuaweicloud.com
ping dns.cn-north-4.myhuaweicloud.com
```

## 🔒 安全建议

1. **保护配置文件**：
   ```bash
   sudo chmod 600 /etc/huaweicloud-dns-updater/config.yaml
   sudo chown root:root /etc/huaweicloud-dns-updater/config.yaml
   ```

2. **AK/SK 管理**：
   - 定期轮换华为云访问密钥
   - 使用IAM用户而非主账号密钥
   - 限制DNS服务的最小权限
   - 避免硬编码敏感信息

3. **网络安全**：
   ```bash
   # 限制防火墙规则（仅允许必要的出站连接）
   sudo ufw allow out 53    # DNS
   sudo ufw allow out 443   # HTTPS
   ```

4. **日志管理**：
   ```bash
   # 定期清理大日志文件
   sudo journalctl --vacuum-size=100M
   
   # 设置日志文件权限
   sudo chmod 640 /var/log/huaweicloud-dns-updater/dns_updater.log
   ```

## 📝 更新日志

### v1.0.0 (2025-06-20)

#### 🎉 首次发布
- ✅ 支持华为云DNS API集成
- ✅ 多域名批量管理
- ✅ 基于Cron的定时任务调度
- ✅ 自动安装脚本和systemd集成
- ✅ 图形化管理工具 `dns-manager`
- ✅ 跨平台支持（14个平台和架构）
- ✅ M4芯片优化编译
- ✅ 完整的错误处理和日志记录

#### 🔧 技术特性
- Go 1.21+ 支持
- 华为云SDK v3集成
- systemd服务保活
- 优雅的信号处理
- 安全权限控制

## 🤝 贡献指南

### 开发环境设置

```bash
# 1. Fork 并克隆仓库
git clone https://github.com/your-username/HuaweicloudUpdater.git
cd HuaweicloudUpdater

# 2. 安装依赖
go mod tidy

# 3. 运行测试
go test ./...

# 4. 编译开发版本
go build -o dns-updater-dev .
```

### 提交规范

- 🎉 `feat`: 新功能
- 🐛 `fix`: 修复bug
- 📚 `docs`: 文档更新
- 🎨 `style`: 代码格式化
- ♻️ `refactor`: 代码重构
- ⚡ `perf`: 性能优化
- ✅ `test`: 测试相关
- 🔧 `chore`: 构建工具、辅助工具等

### 问题反馈

提交Issue时请包含：
- 操作系统和版本
- Go版本（如果从源码编译）
- 错误日志和配置信息（脱敏处理）
- 复现步骤

## 📞 支持与联系

- 🐛 **Bug报告**: [GitHub Issues](https://github.com/yuwan027/HuaweicloudUpdater/issues)
- 💡 **功能建议**: [GitHub Issues](https://github.com/yuwan027/HuaweicloudUpdater/issues)
- 📖 **文档**: [项目Wiki](https://github.com/yuwan027/HuaweicloudUpdater/wiki)
- 📦 **发布版本**: [GitHub Releases](https://github.com/yuwan027/HuaweicloudUpdater/releases)

## 🏆 致谢

- [华为云](https://www.huaweicloud.com/) - 提供DNS API支持
- [robfig/cron](https://github.com/robfig/cron) - Cron表达式解析
- [go-yaml/yaml](https://github.com/go-yaml/yaml) - YAML配置文件支持

## 📜 许可证

本项目采用 [MIT License](LICENSE) 开源协议。

```
MIT License

Copyright (c) 2025 HuaweiCloud DNS Updater

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

**🌟 如果这个项目对您有帮助，请给个Star支持一下！** 