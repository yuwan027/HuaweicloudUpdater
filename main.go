package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
)

// 版本信息
const Version = "1.0.0"

func main() {
	// 命令行参数
	var (
		configPath    = flag.String("config", "config.yaml", "配置文件路径")
		showVersion   = flag.Bool("version", false, "显示版本信息")
		switchNow     = flag.Bool("switch", false, "立即切换到目标IP")
		restoreNow    = flag.Bool("restore", false, "立即恢复到原始IP")
		listJobs      = flag.Bool("list", false, "列出定时任务信息")
		testConfig    = flag.Bool("test", false, "测试配置文件")
	)
	flag.Parse()

	// 显示版本信息
	if *showVersion {
		fmt.Printf("华为云DNS定时更新器 v%s\n", Version)
		return
	}

	// 加载配置
	config, err := LoadConfig(*configPath)
	if err != nil {
		log.Fatalf("加载配置失败: %v", err)
	}

	// 如果只是测试配置文件
	if *testConfig {
		fmt.Println("✅ 配置文件格式正确")
		return
	}

	// 初始化日志
	setupLogging(config.Logging)

	log.Printf("华为云DNS定时更新器 v%s 启动中...", Version)
	log.Printf("配置文件: %s", *configPath)
	log.Printf("管理 %d 个域名", len(config.Domains))

	// 创建DNS客户端
	dnsClient, err := NewDNSClient(
		config.HuaweiCloud.AccessKey,
		config.HuaweiCloud.SecretKey,
		config.HuaweiCloud.Region,
	)
	if err != nil {
		log.Fatalf("创建DNS客户端失败: %v", err)
	}

	// 验证DNS连接和域名配置
	if err := validateDNSConnection(dnsClient, config); err != nil {
		log.Fatalf("DNS连接验证失败: %v", err)
	}

	// 创建调度器
	scheduler := NewScheduler(dnsClient, config)

	// 根据命令行参数执行相应操作
	switch {
	case *switchNow:
		log.Println("立即执行切换到目标IP...")
		scheduler.ExecuteSwitchNow()
		return
	case *restoreNow:
		log.Println("立即执行恢复到原始IP...")
		scheduler.ExecuteRestoreNow()
		return
	case *listJobs:
		if err := scheduler.Start(); err != nil {
			log.Fatalf("启动调度器失败: %v", err)
		}
		scheduler.ListUpcomingJobs()
		scheduler.Stop()
		return
	}

	// 启动定时任务
	if err := scheduler.Start(); err != nil {
		log.Fatalf("启动定时任务失败: %v", err)
	}

	// 显示运行状态
	log.Println("✅ 服务启动成功，等待定时任务执行...")
	scheduler.ListUpcomingJobs()

	// 等待终止信号
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)

	// 阻塞直到收到信号
	<-c

	log.Println("收到终止信号，正在关闭服务...")
	scheduler.Stop()
	log.Println("服务已关闭")
}

// setupLogging 设置日志配置
func setupLogging(logConfig LoggingConfig) {
	// 如果配置了日志文件，输出到文件
	if logConfig.File != "" {
		file, err := os.OpenFile(logConfig.File, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
		if err != nil {
			log.Fatalf("无法打开日志文件: %v", err)
		}
		log.SetOutput(file)
		log.Printf("日志输出到文件: %s", logConfig.File)
	}

	// 设置日志格式
	log.SetFlags(log.LstdFlags | log.Lshortfile)
}

// validateDNSConnection 验证DNS连接和域名配置
func validateDNSConnection(client *DNSClient, config *Config) error {
	log.Println("验证DNS连接和域名配置...")

	for _, domain := range config.Domains {
		log.Printf("验证域名: %s (Zone ID: %s)", domain.Name, domain.ZoneID)
		
		// 尝试获取记录列表来验证连接
		records, err := client.ListRecords(domain.ZoneID)
		if err != nil {
			return fmt.Errorf("无法访问Zone ID %s: %v", domain.ZoneID, err)
		}

		log.Printf("Zone %s 包含 %d 条记录", domain.ZoneID, len(records))

		// 查找对应的记录
		record, err := client.FindRecord(domain.ZoneID, domain.Name, domain.RecordType)
		if err != nil {
			log.Printf("⚠️  域名 %s 的 %s 记录不存在，将在首次更新时创建", domain.Name, domain.RecordType)
		} else {
			log.Printf("✅ 找到域名 %s 的 %s 记录，当前值: %s", domain.Name, domain.RecordType, record.Value)
		}
	}

	log.Println("✅ 所有域名配置验证完成")
	return nil
} 