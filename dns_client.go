package main

import (
	"fmt"
	"log"

	"github.com/huaweicloud/huaweicloud-sdk-go-v3/core/auth/basic"
	"github.com/huaweicloud/huaweicloud-sdk-go-v3/core/config"
	"github.com/huaweicloud/huaweicloud-sdk-go-v3/core/region"
	dns "github.com/huaweicloud/huaweicloud-sdk-go-v3/services/dns/v2"
	"github.com/huaweicloud/huaweicloud-sdk-go-v3/services/dns/v2/model"
)

// DNSClient 华为云DNS客户端
type DNSClient struct {
	client *dns.DnsClient
}

// DNSRecord DNS记录信息
type DNSRecord struct {
	ID     string
	Name   string
	Type   string
	Value  string
	TTL    int32
	ZoneID string
}

// NewDNSClient 创建DNS客户端
func NewDNSClient(accessKey, secretKey, regionName string) (*DNSClient, error) {
	// 创建认证信息
	auth := basic.NewCredentialsBuilder().
		WithAk(accessKey).
		WithSk(secretKey).
		Build()

	// 获取区域信息
	reg, err := region.SafeValueOf(regionName)
	if err != nil {
		return nil, fmt.Errorf("无效的区域: %v", err)
	}

	// 创建客户端配置
	hcConfig := config.DefaultConfigBuilder().
		WithRegion(reg).
		WithCredential(auth).
		Build()

	// 创建DNS客户端
	client := dns.NewDnsClient(hcConfig)

	return &DNSClient{client: client}, nil
}

// ListRecords 列出指定区域的所有DNS记录
func (c *DNSClient) ListRecords(zoneID string) ([]DNSRecord, error) {
	request := &model.ListRecordSetsRequest{
		ZoneId: zoneID,
	}

	response, err := c.client.ListRecordSets(request)
	if err != nil {
		return nil, fmt.Errorf("获取DNS记录失败: %v", err)
	}

	var records []DNSRecord
	if response.Recordsets != nil {
		for _, record := range *response.Recordsets {
			if record.Id != nil && record.Name != nil && record.Type != nil {
				dnsRecord := DNSRecord{
					ID:     *record.Id,
					Name:   *record.Name,
					Type:   *record.Type,
					ZoneID: zoneID,
				}
				
				if record.Records != nil && len(*record.Records) > 0 {
					dnsRecord.Value = (*record.Records)[0]
				}
				
				if record.Ttl != nil {
					dnsRecord.TTL = *record.Ttl
				}
				
				records = append(records, dnsRecord)
			}
		}
	}

	return records, nil
}

// FindRecord 查找指定名称和类型的DNS记录
func (c *DNSClient) FindRecord(zoneID, name, recordType string) (*DNSRecord, error) {
	records, err := c.ListRecords(zoneID)
	if err != nil {
		return nil, err
	}

	for _, record := range records {
		if record.Name == name && record.Type == recordType {
			return &record, nil
		}
	}

	return nil, fmt.Errorf("未找到记录: %s (类型: %s)", name, recordType)
}

// UpdateRecord 更新DNS记录
func (c *DNSClient) UpdateRecord(zoneID, recordID, newValue string, ttl int32) error {
	records := []string{newValue}
	
	request := &model.UpdateRecordSetRequest{
		ZoneId:      zoneID,
		RecordsetId: recordID,
		Body: &model.UpdateRecordSetReq{
			Records: &records,
			Ttl:     &ttl,
		},
	}

	_, err := c.client.UpdateRecordSet(request)
	if err != nil {
		return fmt.Errorf("更新DNS记录失败: %v", err)
	}

	return nil
}

// CreateRecord 创建新的DNS记录
func (c *DNSClient) CreateRecord(zoneID, name, recordType, value string, ttl int32) error {
	records := []string{value}
	
	request := &model.CreateRecordSetRequest{
		ZoneId: zoneID,
		Body: &model.CreateRecordSetRequestBody{
			Name:    name,
			Type:    recordType,
			Records: &records,
			Ttl:     &ttl,
		},
	}

	_, err := c.client.CreateRecordSet(request)
	if err != nil {
		return fmt.Errorf("创建DNS记录失败: %v", err)
	}

	return nil
}

// UpdateDomainRecord 更新域名记录（如果不存在则创建）
func (c *DNSClient) UpdateDomainRecord(domain DomainConfig, newIP string) error {
	// 首先尝试查找现有记录
	record, err := c.FindRecord(domain.ZoneID, domain.Name, domain.RecordType)
	if err != nil {
		// 记录不存在，创建新记录
		log.Printf("记录不存在，创建新记录: %s -> %s", domain.Name, newIP)
		return c.CreateRecord(domain.ZoneID, domain.Name, domain.RecordType, newIP, domain.TTL)
	}

	// 检查是否需要更新
	if record.Value == newIP {
		log.Printf("域名 %s 的IP已是目标值 %s，无需更新", domain.Name, newIP)
		return nil
	}

	// 更新现有记录
	log.Printf("更新域名记录: %s %s -> %s", domain.Name, record.Value, newIP)
	return c.UpdateRecord(domain.ZoneID, record.ID, newIP, domain.TTL)
} 