package models

// ModelType AI模型类型
type ModelType string

const (
	ModelClassification    ModelType = "CLASSIFICATION"
	ModelRegression        ModelType = "REGRESSION"
	ModelClustering        ModelType = "CLUSTERING"
	ModelNLP              ModelType = "NLP"
	ModelComputerVision   ModelType = "COMPUTER_VISION"
	ModelReinforcement    ModelType = "REINFORCEMENT"
)

// ModelStatus 模型状态
type ModelStatus string

const (
	StatusRegistered ModelStatus = "REGISTERED"
	StatusTraining   ModelStatus = "TRAINING"
	StatusValidated  ModelStatus = "VALIDATED"
	StatusDeployed   ModelStatus = "DEPLOYED"
	StatusDeprecated ModelStatus = "DEPRECATED"
	StatusSuspended  ModelStatus = "SUSPENDED"
)

// AIModel AI模型
type AIModel struct {
	BaseModel
	ModelID          string      `json:"model_id" gorm:"uniqueIndex;size:64;not null;comment:模型唯一标识"`
	Name             string      `json:"name" gorm:"size:255;not null;comment:模型名称"`
	Version          string      `json:"version" gorm:"size:50;not null;comment:模型版本"`
	ModelType        ModelType   `json:"model_type" gorm:"type:enum('CLASSIFICATION','REGRESSION','CLUSTERING','NLP','COMPUTER_VISION','REINFORCEMENT');not null"`
	Algorithm        string      `json:"algorithm" gorm:"size:100;not null;comment:算法类型"`
	Framework        string      `json:"framework" gorm:"size:50;comment:训练框架"`
	CreatorID        uint        `json:"creator_id" gorm:"not null;comment:创建者ID"`
	Creator          User        `json:"creator" gorm:"foreignKey:CreatorID"`
	CreatorAddress   string      `json:"creator_address" gorm:"size:42;not null;comment:创建者地址"`
	Description      string      `json:"description" gorm:"type:text;comment:模型描述"`
	
	// 文件信息
	IPFSHash         string      `json:"ipfs_hash" gorm:"size:64;comment:IPFS文件哈希"`
	FileSize         int64       `json:"file_size" gorm:"comment:文件大小(bytes)"`
	FileFormat       string      `json:"file_format" gorm:"size:20;comment:文件格式"`
	
	// 完整性验证
	IntegrityHash    string      `json:"integrity_hash" gorm:"size:64;not null;comment:完整性哈希"`
	CodeHash         string      `json:"code_hash" gorm:"size:64;comment:代码哈希"`
	
	// 区块链信息
	BlockchainTxHash    string   `json:"blockchain_tx_hash" gorm:"size:66;comment:区块链交易哈希"`
	BlockchainBlockNum  int64    `json:"blockchain_block_number" gorm:"comment:区块号"`
	
	// 状态信息
	Status           ModelStatus `json:"status" gorm:"type:enum('REGISTERED','TRAINING','VALIDATED','DEPLOYED','DEPRECATED','SUSPENDED');default:'REGISTERED'"`
	IsPublic         bool        `json:"is_public" gorm:"default:false;comment:是否公开"`
	IsVerified       bool        `json:"is_verified" gorm:"default:false;comment:是否已验证"`
	
	// 关联数据
	Metrics          []ModelMetric    `json:"metrics,omitempty" gorm:"foreignKey:ModelID;references:ModelID"`
	TrainingData     []TrainingData   `json:"training_data,omitempty" gorm:"foreignKey:ModelID;references:ModelID"`
	Deployments      []Deployment     `json:"deployments,omitempty" gorm:"foreignKey:ModelID;references:ModelID"`
	Audits          []Audit          `json:"audits,omitempty" gorm:"foreignKey:ModelID;references:ModelID"`
}

// ModelMetric 模型性能指标
type ModelMetric struct {
	BaseModel
	ModelID       string  `json:"model_id" gorm:"size:64;not null;index"`
	Accuracy      float64 `json:"accuracy" gorm:"comment:准确率"`
	Precision     float64 `json:"precision" gorm:"comment:精确率"`
	Recall        float64 `json:"recall" gorm:"comment:召回率"`
	F1Score       float64 `json:"f1_score" gorm:"comment:F1分数"`
	TrainingTime  int64   `json:"training_time" gorm:"comment:训练时间(秒)"`
	ModelSize     int64   `json:"model_size" gorm:"comment:模型大小(bytes)"`
	AdditionalMetrics string `json:"additional_metrics" gorm:"type:text;comment:其他指标(JSON格式)"`
}

// CreateModelRequest 创建模型请求
type CreateModelRequest struct {
	ModelID     string    `json:"model_id" binding:"required,min=1,max=64"`
	Name        string    `json:"name" binding:"required,min=1,max=255"`
	Version     string    `json:"version" binding:"required,min=1,max=50"`
	ModelType   ModelType `json:"model_type" binding:"required,oneof=CLASSIFICATION REGRESSION CLUSTERING NLP COMPUTER_VISION REINFORCEMENT"`
	Algorithm   string    `json:"algorithm" binding:"required,min=1,max=100"`
	Framework   string    `json:"framework" binding:"omitempty,max=50"`
	Description string    `json:"description" binding:"omitempty,max=1000"`
}

// UpdateModelRequest 更新模型请求
type UpdateModelRequest struct {
	Name        string `json:"name" binding:"omitempty,min=1,max=255"`
	Version     string `json:"version" binding:"omitempty,min=1,max=50"`
	Description string `json:"description" binding:"omitempty,max=1000"`
	Framework   string `json:"framework" binding:"omitempty,max=50"`
}

// ModelResponse 模型响应
type ModelResponse struct {
	ID               uint          `json:"id"`
	ModelID          string        `json:"model_id"`
	Name             string        `json:"name"`
	Version          string        `json:"version"`
	ModelType        ModelType     `json:"model_type"`
	Algorithm        string        `json:"algorithm"`
	Framework        string        `json:"framework"`
	Creator          UserResponse  `json:"creator"`
	Description      string        `json:"description"`
	Status           ModelStatus   `json:"status"`
	IsPublic         bool          `json:"is_public"`
	IsVerified       bool          `json:"is_verified"`
	IntegrityHash    string        `json:"integrity_hash"`
	BlockchainTxHash string        `json:"blockchain_tx_hash"`
	CreatedAt        string        `json:"created_at"`
	UpdatedAt        string        `json:"updated_at"`
}
