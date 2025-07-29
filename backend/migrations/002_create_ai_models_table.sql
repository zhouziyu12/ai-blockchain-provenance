-- AI模型表
CREATE TABLE IF NOT EXISTS ai_models (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    model_id VARCHAR(64) UNIQUE NOT NULL COMMENT '模型唯一标识',
    name VARCHAR(255) NOT NULL COMMENT '模型名称',
    version VARCHAR(50) NOT NULL COMMENT '模型版本',
    model_type ENUM('CLASSIFICATION', 'REGRESSION', 'CLUSTERING', 'NLP', 'COMPUTER_VISION', 'REINFORCEMENT') NOT NULL,
    algorithm VARCHAR(100) NOT NULL COMMENT '算法类型',
    framework VARCHAR(50) COMMENT '训练框架',
    creator_id BIGINT NOT NULL COMMENT '创建者ID',
    creator_address VARCHAR(42) NOT NULL COMMENT '创建者地址',
    description TEXT COMMENT '模型描述',
    
    -- 文件信息
    ipfs_hash VARCHAR(64) COMMENT 'IPFS文件哈希',
    file_size BIGINT COMMENT '文件大小(bytes)',
    file_format VARCHAR(20) COMMENT '文件格式',
    
    -- 完整性验证
    integrity_hash VARCHAR(64) NOT NULL COMMENT '完整性哈希',
    code_hash VARCHAR(64) COMMENT '代码哈希',
    
    -- 区块链信息
    blockchain_tx_hash VARCHAR(66) COMMENT '区块链交易哈希',
    blockchain_block_number BIGINT COMMENT '区块号',
    
    -- 状态信息
    status ENUM('REGISTERED', 'TRAINING', 'VALIDATED', 'DEPLOYED', 'DEPRECATED', 'SUSPENDED') DEFAULT 'REGISTERED',
    is_public BOOLEAN DEFAULT FALSE COMMENT '是否公开',
    is_verified BOOLEAN DEFAULT FALSE COMMENT '是否已验证',
    
    -- 时间戳
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_model_id (model_id),
    INDEX idx_creator_id (creator_id),
    INDEX idx_status (status),
    INDEX idx_model_type (model_type),
    INDEX idx_created_at (created_at),
    FULLTEXT idx_name_desc (name, description)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
