package models

import (
	"database/sql/driver"
	"encoding/json"
	"fmt"
)

// KYCStatus KYC验证状态
type KYCStatus string

const (
	KYCPending  KYCStatus = "PENDING"
	KYCVerified KYCStatus = "VERIFIED"
	KYCRejected KYCStatus = "REJECTED"
)

// Permissions 权限列表
type Permissions []string

// Value 实现 driver.Valuer 接口
func (p Permissions) Value() (driver.Value, error) {
	if len(p) == 0 {
		return "[]", nil
	}
	return json.Marshal(p)
}

// Scan 实现 sql.Scanner 接口
func (p *Permissions) Scan(value interface{}) error {
	if value == nil {
		*p = []string{}
		return nil
	}

	var bytes []byte
	switch v := value.(type) {
	case []byte:
		bytes = v
	case string:
		bytes = []byte(v)
	default:
		return fmt.Errorf("cannot scan %T into Permissions", value)
	}

	return json.Unmarshal(bytes, p)
}

// User 用户模型
type User struct {
	BaseModel
	Address   string    `json:"address" gorm:"uniqueIndex;size:42;not null;comment:以太坊地址"`
	Username  string    `json:"username" gorm:"uniqueIndex;size:50;comment:用户名"`
	Email     string    `json:"email" gorm:"uniqueIndex;size:100;comment:邮箱"`
	Phone     string    `json:"phone" gorm:"size:20;comment:手机号"`
	AvatarURL string    `json:"avatar_url" gorm:"size:255;comment:头像URL"`
	Bio       string    `json:"bio" gorm:"type:text;comment:个人简介"`
	KYCStatus KYCStatus `json:"kyc_status" gorm:"type:enum('PENDING','VERIFIED','REJECTED');default:'PENDING'"`
	IsActive  bool      `json:"is_active" gorm:"default:true"`
	RoleID    uint      `json:"role_id" gorm:"not null"`
	Role      Role      `json:"role" gorm:"foreignKey:RoleID"`
}

// Role 角色模型
type Role struct {
	BaseModel
	Name        string      `json:"name" gorm:"uniqueIndex;size:50;not null;comment:角色名称"`
	DisplayName string      `json:"display_name" gorm:"size:100;not null;comment:显示名称"`
	Description string      `json:"description" gorm:"type:text;comment:角色描述"`
	Permissions Permissions `json:"permissions" gorm:"type:json;comment:权限列表"`
	IsActive    bool        `json:"is_active" gorm:"default:true"`
	Users       []User      `json:"users,omitempty" gorm:"foreignKey:RoleID"`
}

// CreateUserRequest 创建用户请求
type CreateUserRequest struct {
	Address  string `json:"address" binding:"required,eth_addr"`
	Username string `json:"username" binding:"omitempty,min=3,max=50"`
	Email    string `json:"email" binding:"omitempty,email"`
	Phone    string `json:"phone" binding:"omitempty,max=20"`
	Bio      string `json:"bio" binding:"omitempty,max=500"`
	RoleID   uint   `json:"role_id" binding:"required"`
}

// UpdateUserRequest 更新用户请求
type UpdateUserRequest struct {
	Username  string `json:"username" binding:"omitempty,min=3,max=50"`
	Email     string `json:"email" binding:"omitempty,email"`
	Phone     string `json:"phone" binding:"omitempty,max=20"`
	AvatarURL string `json:"avatar_url" binding:"omitempty,url"`
	Bio       string `json:"bio" binding:"omitempty,max=500"`
}

// UserResponse 用户响应
type UserResponse struct {
	ID        uint      `json:"id"`
	Address   string    `json:"address"`
	Username  string    `json:"username"`
	Email     string    `json:"email"`
	AvatarURL string    `json:"avatar_url"`
	Bio       string    `json:"bio"`
	KYCStatus KYCStatus `json:"kyc_status"`
	IsActive  bool      `json:"is_active"`
	Role      Role      `json:"role"`
	CreatedAt string    `json:"created_at"`
	UpdatedAt string    `json:"updated_at"`
}
