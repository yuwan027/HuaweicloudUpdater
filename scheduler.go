package main

import (
	"log"

	"github.com/robfig/cron/v3"
)

// Scheduler 定时任务调度器
type Scheduler struct {
	cron      *cron.Cron
	dnsClient *DNSClient
	config    *Config
}

// NewScheduler 创建新的调度器
func NewScheduler(dnsClient *DNSClient, config *Config) *Scheduler {
	c := cron.New(cron.WithSeconds())
	return &Scheduler{
		cron:      c,
		dnsClient: dnsClient,
		config:    config,
	}
}

// Start 启动定时任务
func (s *Scheduler) Start() error {
	// 添加切换到目标IP的任务
	_, err := s.cron.AddFunc(s.config.Schedule.SwitchToTarget, s.switchToTarget)
	if err != nil {
		return err
	}
	log.Printf("已添加切换到目标IP的定时任务: %s", s.config.Schedule.SwitchToTarget)

	// 如果配置了恢复时间，添加恢复到原始IP的任务
	if s.config.Schedule.RestoreToOriginal != "" {
		_, err := s.cron.AddFunc(s.config.Schedule.RestoreToOriginal, s.restoreToOriginal)
		if err != nil {
			return err
		}
		log.Printf("已添加恢复到原始IP的定时任务: %s", s.config.Schedule.RestoreToOriginal)
	}

	// 启动调度器
	s.cron.Start()
	log.Println("定时任务调度器已启动")

	return nil
}

// Stop 停止定时任务
func (s *Scheduler) Stop() {
	s.cron.Stop()
	log.Println("定时任务调度器已停止")
}

// switchToTarget 切换到目标IP
func (s *Scheduler) switchToTarget() {
	log.Println("开始执行切换到目标IP的任务...")
	
	for _, domain := range s.config.Domains {
		err := s.dnsClient.UpdateDomainRecord(domain, domain.TargetIP)
		if err != nil {
			log.Printf("更新域名 %s 到目标IP %s 失败: %v", domain.Name, domain.TargetIP, err)
		} else {
			log.Printf("成功将域名 %s 切换到目标IP %s", domain.Name, domain.TargetIP)
		}
	}
	
	log.Println("切换到目标IP的任务执行完成")
}

// restoreToOriginal 恢复到原始IP
func (s *Scheduler) restoreToOriginal() {
	log.Println("开始执行恢复到原始IP的任务...")
	
	for _, domain := range s.config.Domains {
		err := s.dnsClient.UpdateDomainRecord(domain, domain.OriginalIP)
		if err != nil {
			log.Printf("恢复域名 %s 到原始IP %s 失败: %v", domain.Name, domain.OriginalIP, err)
		} else {
			log.Printf("成功将域名 %s 恢复到原始IP %s", domain.Name, domain.OriginalIP)
		}
	}
	
	log.Println("恢复到原始IP的任务执行完成")
}

// ExecuteSwitchNow 立即执行切换到目标IP
func (s *Scheduler) ExecuteSwitchNow() {
	s.switchToTarget()
}

// ExecuteRestoreNow 立即执行恢复到原始IP
func (s *Scheduler) ExecuteRestoreNow() {
	s.restoreToOriginal()
}

// ListUpcomingJobs 列出即将执行的任务
func (s *Scheduler) ListUpcomingJobs() {
	entries := s.cron.Entries()
	log.Printf("共有 %d 个定时任务:", len(entries))
	
	for i, entry := range entries {
		log.Printf("任务 %d: 下次执行时间 %s", i+1, entry.Next.Format("2006-01-02 15:04:05"))
	}
} 