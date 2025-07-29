# AI模型溯源系统 - 智能合约交互指南

## 合约列表

| 序号 | 合约名称 | 主要功能 |
|------|---------|---------|
| 1 | AIModelRegistry | 模型注册、版本管理、完整性验证 |
| 2 | AIModelTokenV2 | 统一代币经济、多类型质押 |
| 3 | TrainingDataManager | 训练数据溯源、血缘关系 |
| 4 | DeploymentManager | 部署生命周期追踪 |
| 5 | AuditManager | 第三方审计、信誉评分 |
| 6 | GovernanceManager | 去中心化治理、提案投票 |
| 7 | AIModelNFT | 模型NFT化、资产确权 |
| 8 | AIModelInsuranceV2 | 保险风险管理 |
| 9 | AIModelPredictionMarket | 预测市场、众包智慧 |
| 10 | FederatedLearningCoordinator | 联邦学习协调 |
| 11 | AIModelMarketplace | 模型租赁市场 |

## 核心交互流程

### 1. 模型注册流程
const registry = new ethers.Contract(address, abi, signer);
const tx = await registry.registerModel("model_001", "图像分类模型", "v1.0.0", 0, "CNN");
await tx.wait();
const model = await registry.getModel("model_001");

### 2. 代币质押流程
const token = new ethers.Contract(address, abi, signer);
const stakeAmount = ethers.parseEther("1000");
const tx = await token.stakeTokens(1, stakeAmount, "model_001");
await tx.wait();

### 3. 保险购买流程
const insurance = new ethers.Contract(address, abi, signer);
const premium = await insurance.calculatePremium("model_001", 0, ethers.parseEther("5000"), 90 * 24 * 3600);
await token.approve(insuranceAddress, premium);
const tx = await insurance.createPolicy("model_001", 0, ethers.parseEther("5000"), 90 * 24 * 3600, ethers.parseEther("500"), termsHash);

## API接口设计
- POST /api/v1/models - 注册模型
- GET /api/v1/models - 查询模型列表
- GET /api/v1/models/{id} - 获取模型详情
- POST /api/v1/tokens/stake - 质押代币
- POST /api/v1/insurance/purchase - 购买保险

## 安全最佳实践
1. 权限控制 - 使用AccessControl管理角色
2. 重入保护 - 使用ReentrancyGuard
3. 输入验证 - 严格验证用户输入
4. 事件记录 - 记录关键操作用于审计
