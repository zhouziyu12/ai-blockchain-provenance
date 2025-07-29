// Sepolia网络配置
export const NETWORK_CONFIG = {
  chainId: 11155111,
  name: 'Sepolia',
  rpcUrl: 'https://sepolia.infura.io/v3/315dbedded6b4b37a95b73281cb81e22',
  blockExplorer: 'https://sepolia.etherscan.io',
  nativeCurrency: {
    name: 'ETH',
    symbol: 'ETH',
    decimals: 18
  }
};

// 合约地址 (部署后更新)
export const CONTRACT_ADDRESSES = {
  AIModelRegistry: '',
  AIModelTokenV2: '',
  TrainingDataManager: '',
  DeploymentManager: '',
  AuditManager: '',
  GovernanceManager: '',
  AIModelNFT: '',
  AIModelInsuranceV2: '',
  AIModelPredictionMarket: '',
  FederatedLearningCoordinator: '',
  AIModelMarketplace: ''
};

// 合约ABI (部署后更新)
export const CONTRACT_ABIS = {
  // 从contract-abis.json复制
};
