package main

import (
	"fmt"
	"os"

	"gopkg.in/yaml.v3"
)

// Config 主配置结构
type Config struct {
	HuaweiCloud HuaweiCloudConfig `yaml:"huaweicloud"`
	Domains     []DomainConfig    `yaml:"domains"`
	Schedule    ScheduleConfig    `yaml:"schedule"`
	Logging     LoggingConfig     `yaml:"logging"`
}

// HuaweiCloudConfig 华为云配置
type HuaweiCloudConfig struct {
	AccessKey string `yaml:"access_key"`
	SecretKey string `yaml:"secret_key"`
	Region    string `yaml:"region"`
}

// DomainConfig 域名配置
type DomainConfig struct {
	Name       string `yaml:"name"`
	ZoneID     string `yaml:"zone_id"`
	OriginalIP string `yaml:"original_ip"`
	TargetIP   string `yaml:"target_ip"`
	RecordType string `yaml:"record_type"`
	TTL        int32  `yaml:"ttl"`
}

// ScheduleConfig 定时任务配置
type ScheduleConfig struct {
	SwitchToTarget     string `yaml:"switch_to_target"`
	RestoreToOriginal  string `yaml:"restore_to_original"`
}

// LoggingConfig 日志配置
type LoggingConfig struct {
	Level string `yaml:"level"`
	File  string `yaml:"file"`
}

// LoadConfig 从文件加载配置
func LoadConfig(configPath string) (*Config, error) {
	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("读取配置文件失败: %v", err)
	}

	var config Config
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("解析配置文件失败: %v", err)
	}

	// 验证配置
	if err := validateConfig(&config); err != nil {
		return nil, err
	}

	return &config, nil
}

// validateConfig 验证配置的有效性
func validateConfig(config *Config) error {
	if config.HuaweiCloud.AccessKey == "" || config.HuaweiCloud.AccessKey == "YOUR_ACCESS_KEY" {
		return fmt.Errorf("请配置有效的华为云 AccessKey")
	}

	if config.HuaweiCloud.SecretKey == "" || config.HuaweiCloud.SecretKey == "YOUR_SECRET_KEY" {
		return fmt.Errorf("请配置有效的华为云 SecretKey")
	}

	if len(config.Domains) == 0 {
		return fmt.Errorf("至少需要配置一个域名")
	}

	for i, domain := range config.Domains {
		if domain.Name == "" {
			return fmt.Errorf("域名 %d: 名称不能为空", i+1)
		}
		if domain.ZoneID == "" {
			return fmt.Errorf("域名 %s: ZoneID 不能为空", domain.Name)
		}
		if domain.OriginalIP == "" {
			return fmt.Errorf("域名 %s: 原始IP不能为空", domain.Name)
		}
		if domain.TargetIP == "" {
			return fmt.Errorf("域名 %s: 目标IP不能为空", domain.Name)
		}
	}

	if config.Schedule.SwitchToTarget == "" {
		return fmt.Errorf("必须配置切换到目标IP的时间")
	}

	return nil
} 