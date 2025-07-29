-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    address VARCHAR(42) UNIQUE NOT NULL COMMENT '以太坊地址',
    username VARCHAR(50) UNIQUE COMMENT '用户名',
    email VARCHAR(100) UNIQUE COMMENT '邮箱',
    phone VARCHAR(20) COMMENT '手机号',
    avatar_url VARCHAR(255) COMMENT '头像URL',
    bio TEXT COMMENT '个人简介',
    kyc_status ENUM('PENDING', 'VERIFIED', 'REJECTED') DEFAULT 'PENDING',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_address (address),
    INDEX idx_email (email),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 角色表
CREATE TABLE IF NOT EXISTS roles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) UNIQUE NOT NULL COMMENT '角色名称',
    display_name VARCHAR(100) NOT NULL COMMENT '显示名称',
    description TEXT COMMENT '角色描述',
    permissions JSON COMMENT '权限列表',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 初始化角色数据
INSERT INTO roles (name, display_name, description, permissions) VALUES 
('ADMIN', '系统管理员', '系统最高权限管理员', '["ALL"]'),
('MODEL_CREATOR', '模型创建者', '可以创建和管理AI模型', '["CREATE_MODEL", "UPDATE_MODEL", "DELETE_MODEL"]'),
('AUDITOR', '审计员', '负责模型审计和认证', '["AUDIT_MODEL", "VIEW_MODEL"]'),
('USER', '普通用户', '基础用户权限', '["VIEW_MODEL", "USE_MODEL"]'),
('VALIDATOR', '验证者', '负责模型验证和质押', '["VALIDATE_MODEL", "STAKE_TOKEN"]');
