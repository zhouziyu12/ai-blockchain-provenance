const { ethers } = require("hardhat");
const fs = require('fs');

async function main() {
  console.log("📋 生成合约ABI文件...");
  
  const contractNames = [
    "AIModelRegistry",
    "AIModelTokenV2", 
    "TrainingDataManager",
    "DeploymentManager",
    "AuditManager",
    "GovernanceManager",
    "AIModelNFT",
    "AIModelInsuranceV2",
    "AIModelPredictionMarket",
    "FederatedLearningCoordinator",
    "AIModelMarketplace"
  ];
  
  const contractABIs = {};
  const contractBytecodes = {};
  
  for (const contractName of contractNames) {
    try {
      console.log(`⚙️ 提取 ${contractName} ABI...`);
      
      const ContractFactory = await ethers.getContractFactory(contractName);
      
      // 获取ABI
      contractABIs[contractName] = ContractFactory.interface.format('json');
      
      // 获取字节码
      contractBytecodes[contractName] = ContractFactory.bytecode;
      
      console.log(`✅ ${contractName} ABI提取完成`);
      
    } catch (error) {
      console.error(`❌ ${contractName} ABI提取失败:`, error.message);
    }
  }
  
  // 保存ABI文件
  fs.writeFileSync('contract-abis.json', JSON.stringify(contractABIs, null, 2));
  console.log("📁 ABI文件已保存到 contract-abis.json");
  
  // 保存字节码文件
  fs.writeFileSync('contract-bytecodes.json', JSON.stringify(contractBytecodes, null, 2));
  console.log("📁 字节码文件已保存到 contract-bytecodes.json");
  
  // 生成前端可用的配置文件
  const frontendConfig = {
    networkConfig: {
      chainId: 11155111,
      name: 'Sepolia',
      rpcUrl: 'https://sepolia.infura.io/v3/315dbedded6b4b37a95b73281cb81e22',
      blockExplorer: 'https://sepolia.etherscan.io'
    },
    contracts: {}
  };
  
  // 读取合约地址
  if (fs.existsSync('sepolia-contracts.json')) {
    const deployedContracts = JSON.parse(fs.readFileSync('sepolia-contracts.json', 'utf8'));
    
    for (const contractName of contractNames) {
      if (deployedContracts.contracts[contractName] && contractABIs[contractName]) {
        frontendConfig.contracts[contractName] = {
          address: deployedContracts.contracts[contractName],
          abi: JSON.parse(contractABIs[contractName])
        };
      }
    }
  }
  
  // 保存前端配置
  fs.writeFileSync('frontend-config.json', JSON.stringify(frontendConfig, null, 2));
  console.log("📁 前端配置已保存到 frontend-config.json");
  
  // 生成Golang结构体定义
  const goConfig = `package config

// Contract addresses on Sepolia testnet
var ContractAddresses = map[string]string{
${contractNames.map(name => {
    const deployedContracts = JSON.parse(fs.readFileSync('sepolia-contracts.json', 'utf8'));
    const address = deployedContracts.contracts[name] || '';
    return `    "${name}": "${address}",`;
  }).join('\n')}
}

// Network configuration
const (
    ChainID = 11155111
    RPCUrl  = "https://sepolia.infura.io/v3/315dbedded6b4b37a95b73281cb81e22"
    NetworkName = "sepolia"
)
`;
  
  // 创建backend配置目录
  if (!fs.existsSync('backend/internal/config')) {
    fs.mkdirSync('backend/internal/config', { recursive: true });
  }
  
  fs.writeFileSync('backend/internal/config/contracts.go', goConfig);
  console.log("📁 Golang配置已保存到 backend/internal/config/contracts.go");
  
  console.log("\n🎉 所有ABI和配置文件生成完成!");
  console.log("✅ contract-abis.json - 合约ABI");
  console.log("✅ contract-bytecodes.json - 合约字节码");  
  console.log("✅ frontend-config.json - 前端配置");
  console.log("✅ backend/internal/config/contracts.go - 后端配置");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
