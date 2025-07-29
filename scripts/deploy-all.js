const { ethers } = require("hardhat");

async function main() {
  console.log("🚀 开始部署AI模型溯源生态系统...");
  
  const [deployer] = await ethers.getSigners();
  console.log("部署账户:", deployer.address);
  console.log("账户余额:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)));

  // 1. 部署核心模型注册合约
  console.log("\n📝 部署AI模型注册合约...");
  const AIModelRegistry = await ethers.getContractFactory("AIModelRegistry");
  const modelRegistry = await AIModelRegistry.deploy();
  console.log("✅ AIModelRegistry 部署到:", await modelRegistry.getAddress());

  // 2. 部署统一代币合约
  console.log("\n💰 部署统一代币合约...");
  const AIModelTokenV2 = await ethers.getContractFactory("AIModelTokenV2");
  const aimtToken = await AIModelTokenV2.deploy();
  console.log("✅ AIModelTokenV2 部署到:", await aimtToken.getAddress());

  // 3. 部署训练数据管理合约
  console.log("\n🗄️ 部署训练数据管理合约...");
  const TrainingDataManager = await ethers.getContractFactory("TrainingDataManager");
  const dataManager = await TrainingDataManager.deploy();
  console.log("✅ TrainingDataManager 部署到:", await dataManager.getAddress());

  // 4. 部署部署管理合约
  console.log("\n🚀 部署部署管理合约...");
  const DeploymentManager = await ethers.getContractFactory("DeploymentManager");
  const deploymentManager = await DeploymentManager.deploy();
  console.log("✅ DeploymentManager 部署到:", await deploymentManager.getAddress());

  // 5. 部署审计管理合约
  console.log("\n🔍 部署审计管理合约...");
  const AuditManager = await ethers.getContractFactory("AuditManager");
  const auditManager = await AuditManager.deploy();
  console.log("✅ AuditManager 部署到:", await auditManager.getAddress());

  // 6. 部署治理合约
  console.log("\n🗳️ 部署治理合约...");
  const GovernanceManager = await ethers.getContractFactory("GovernanceManager");
  const governanceManager = await GovernanceManager.deploy();
  console.log("✅ GovernanceManager 部署到:", await governanceManager.getAddress());

  // 7. 部署NFT合约
  console.log("\n🎨 部署AI模型NFT合约...");
  const AIModelNFT = await ethers.getContractFactory("AIModelNFT");
  const modelNFT = await AIModelNFT.deploy();
  console.log("✅ AIModelNFT 部署到:", await modelNFT.getAddress());

  // 8. 部署保险合约
  console.log("\n🛡️ 部署保险合约...");
  const AIModelInsuranceV2 = await ethers.getContractFactory("AIModelInsuranceV2");
  const insurance = await AIModelInsuranceV2.deploy(await aimtToken.getAddress());
  console.log("✅ AIModelInsuranceV2 部署到:", await insurance.getAddress());

  // 9. 部署预测市场合约
  console.log("\n🎯 部署预测市场合约...");
  const AIModelPredictionMarket = await ethers.getContractFactory("AIModelPredictionMarket");
  const predictionMarket = await AIModelPredictionMarket.deploy();
  console.log("✅ AIModelPredictionMarket 部署到:", await predictionMarket.getAddress());

  // 10. 部署联邦学习合约
  console.log("\n🤝 部署联邦学习合约...");
  const FederatedLearningCoordinator = await ethers.getContractFactory("FederatedLearningCoordinator");
  const federatedLearning = await FederatedLearningCoordinator.deploy();
  console.log("✅ FederatedLearningCoordinator 部署到:", await federatedLearning.getAddress());

  // 11. 部署市场合约
  console.log("\n🏪 部署模型市场合约...");
  const AIModelMarketplace = await ethers.getContractFactory("AIModelMarketplace");
  const marketplace = await AIModelMarketplace.deploy();
  console.log("✅ AIModelMarketplace 部署到:", await marketplace.getAddress());

  // 设置权限和初始化
  console.log("\n⚙️ 设置合约权限和初始化...");
  
  // 给保险合约设置代币权限
  await aimtToken.grantRole(await aimtToken.INSURANCE_ROLE(), await insurance.getAddress());
  console.log("✅ 保险合约权限设置完成");

  // 保存部署地址
  const deployedContracts = {
    AIModelRegistry: await modelRegistry.getAddress(),
    AIModelTokenV2: await aimtToken.getAddress(),
    TrainingDataManager: await dataManager.getAddress(),
    DeploymentManager: await deploymentManager.getAddress(),
    AuditManager: await auditManager.getAddress(),
    GovernanceManager: await governanceManager.getAddress(),
    AIModelNFT: await modelNFT.getAddress(),
    AIModelInsuranceV2: await insurance.getAddress(),
    AIModelPredictionMarket: await predictionMarket.getAddress(),
    FederatedLearningCoordinator: await federatedLearning.getAddress(),
    AIModelMarketplace: await marketplace.getAddress(),
  };

  console.log("\n📋 部署总结:");
  console.log("=".repeat(50));
  Object.entries(deployedContracts).forEach(([name, address]) => {
    console.log(`${name}: ${address}`);
  });

  console.log("\n🎉 AI模型溯源生态系统部署完成!");
  console.log("💡 提示: 可以使用以下地址与合约交互");
  
  // 写入文件
  const fs = require('fs');
  fs.writeFileSync(
    'deployed-contracts.json', 
    JSON.stringify(deployedContracts, null, 2)
  );
  console.log("📁 合约地址已保存到 deployed-contracts.json");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
