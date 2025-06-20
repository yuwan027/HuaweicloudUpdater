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

## 安装与配置

### 1. 环境要求

- Go 1.21 或更高版本
- 华为云账号和有效的访问密钥(AK/SK)
- 已配置的DNS私有域名

### 2. 编译程序

```bash
# 下载依赖
go mod tidy

# 编译程序
go build -o dns-updater .

# 或者直接运行
go run .
```

### 3. 配置文件

复制 `config.yaml` 并根据实际情况修改配置：

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

## 使用方法

### 基本用法

```bash
# 启动定时服务
./dns-updater

# 使用自定义配置文件
./dns-updater -config /path/to/config.yaml

# 测试配置文件
./dns-updater -test

# 显示版本信息
./dns-updater -version
```

### 手动操作

```bash
# 立即切换到目标IP
./dns-updater -switch

# 立即恢复到原始IP
./dns-updater -restore

# 查看定时任务信息
./dns-updater -list
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

## 常见问题

### 1. 认证失败
检查 AK/SK 是否正确，确保账号有DNS服务的操作权限。

### 2. Zone ID 无效
确认 Zone ID 是否正确，检查域名是否已在华为云DNS中配置。

### 3. 记录不存在
程序会自动创建不存在的DNS记录，确保域名配置正确。

### 4. 定时任务不执行
检查Cron表达式格式是否正确，可以使用在线Cron表达式验证工具。

## 系统服务配置

### systemd 服务 (Linux)

创建服务文件 `/etc/systemd/system/dns-updater.service`：

```ini
[Unit]
Description=华为云DNS定时更新器
After=network.target

[Service]
Type=simple
User=your-user
WorkingDirectory=/path/to/dns-updater
ExecStart=/path/to/dns-updater/dns-updater
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

启动服务：
```bash
sudo systemctl daemon-reload
sudo systemctl enable dns-updater
sudo systemctl start dns-updater
```

## 安全建议

1. **保护配置文件**：确保配置文件权限设置为只有所有者可读写 (600)
2. **AK/SK 管理**：定期轮换访问密钥，避免硬编码到代码中
3. **网络安全**：在生产环境中使用防火墙限制访问
4. **日志管理**：定期清理日志文件，避免敏感信息泄露

## 许可证

MIT License

## 贡献

欢迎提交问题和改进建议！ 