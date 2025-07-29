const { ethers } = require("hardhat");
const fs = require('fs');

async function main() {
  console.log("🚀 开始部署到Sepolia测试网...");
  console.log("=" .repeat(60));
  
  const [deployer] = await ethers.getSigners();
  
  console.log(`部署账户: ${deployer.address}`);
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log(`账户余额: ${ethers.formatEther(balance)} ETH`);
  
  // 检查网络
  const network = await ethers.provider.getNetwork();
  console.log(`网络: ${network.name} (Chain ID: ${network.chainId})`);
  
  if (Number(balance) < ethers.parseEther("0.1")) {
    console.error("❌ 账户余额不足！请先获取Sepolia测试币");
    console.log("💡 获取测试币: https://sepoliafaucet.com/");
    return;
  }
  
  const deployedContracts = {};
  const contractABIs = {};
  
  try {
    // 1. 部署核心模型注册合约
    console.log("\n📝 部署AIModelRegistry合约...");
    const AIModelRegistry = await ethers.getContractFactory("AIModelRegistry");
    const modelRegistry = await AIModelRegistry.deploy();
    await modelRegistry.waitForDeployment();
    const modelRegistryAddress = await modelRegistry.getAddress();
    deployedContracts.AIModelRegistry = modelRegistryAddress;
    contractABIs.AIModelRegistry = AIModelRegistry.interface.format('json');
    console.log(`✅ AIModelRegistry: ${modelRegistryAddress}`);
    
    // 2. 部署统一代币合约
    console.log("\n💰 部署AIModelTokenV2合约...");
    const AIModelTokenV2 = await ethers.getContractFactory("AIModelTokenV2");
    const aimtToken = await AIModelTokenV2.deploy();
    await aimtToken.waitForDeployment();
    const aimtTokenAddress = await aimtToken.getAddress();
    deployedContracts.AIModelTokenV2 = aimtTokenAddress;
    contractABIs.AIModelTokenV2 = AIModelTokenV2.interface.format('json');
    console.log(`✅ AIModelTokenV2: ${aimtTokenAddress}`);
    
    // 3. 部署训练数据管理合约
    console.log("\n🗄️ 部署TrainingDataManager合约...");
    const TrainingDataManager = await ethers.getContractFactory("TrainingDataManager");
    const dataManager = await TrainingDataManager.deploy();
    await dataManager.waitForDeployment();
    const dataManagerAddress = await dataManager.getAddress();
    deployedContracts.TrainingDataManager = dataManagerAddress;
    contractABIs.TrainingDataManager = TrainingDataManager.interface.format('json');
    console.log(`✅ TrainingDataManager: ${dataManagerAddress}`);
    
    // 4. 部署部署管理合约
    console.log("\n🚀 部署DeploymentManager合约...");
    const DeploymentManager = await ethers.getContractFactory("DeploymentManager");
    const deploymentManager = await DeploymentManager.deploy();
    await deploymentManager.waitForDeployment();
    const deploymentManagerAddress = await deploymentManager.getAddress();
    deployedContracts.DeploymentManager = deploymentManagerAddress;
    contractABIs.DeploymentManager = DeploymentManager.interface.format('json');
    console.log(`✅ DeploymentManager: ${deploymentManagerAddress}`);
    
    // 5. 部署审计管理合约
    console.log("\n🔍 部署AuditManager合约...");
    const AuditManager = await ethers.getContractFactory("AuditManager");
    const auditManager = await AuditManager.deploy();
    await auditManager.waitForDeployment();
    const auditManagerAddress = await auditManager.getAddress();
    deployedContracts.AuditManager = auditManagerAddress;
    contractABIs.AuditManager = AuditManager.interface.format('json');
    console.log(`✅ AuditManager: ${auditManagerAddress}`);
    
    // 6. 部署治理合约
    console.log("\n🗳️ 部署GovernanceManager合约...");
    const GovernanceManager = await ethers.getContractFactory("GovernanceManager");
    const governanceManager = await GovernanceManager.deploy();
    await governanceManager.waitForDeployment();
    const governanceManagerAddress = await governanceManager.getAddress();
    deployedContracts.GovernanceManager = governanceManagerAddress;
    contractABIs.GovernanceManager = GovernanceManager.interface.format('json');
    console.log(`✅ GovernanceManager: ${governanceManagerAddress}`);
    
    // 7. 部署NFT合约
    console.log("\n🎨 部署AIModelNFT合约...");
    const AIModelNFT = await ethers.getContractFactory("AIModelNFT");
    const modelNFT = await AIModelNFT.deploy();
    await modelNFT.waitForDeployment();
    const modelNFTAddress = await modelNFT.getAddress();
    deployedContracts.AIModelNFT = modelNFTAddress;
    contractABIs.AIModelNFT = AIModelNFT.interface.format('json');
    console.log(`✅ AIModelNFT: ${modelNFTAddress}`);
    
    // 8. 部署保险合约
    console.log("\n🛡️ 部署AIModelInsuranceV2合约...");
    const AIModelInsuranceV2 = await ethers.getContractFactory("AIModelInsuranceV2");
    const insurance = await AIModelInsuranceV2.deploy(aimtTokenAddress);
    await insurance.waitForDeployment();
    const insuranceAddress = await insurance.getAddress();
    deployedContracts.AIModelInsuranceV2 = insuranceAddress;
    contractABIs.AIModelInsuranceV2 = AIModelInsuranceV2.interface.format('json');
    console.log(`✅ AIModelInsuranceV2: ${insuranceAddress}`);
    
    // 9. 部署预测市场合约
    console.log("\n🎯 部署AIModelPredictionMarket合约...");
    const AIModelPredictionMarket = await ethers.getContractFactory("AIModelPredictionMarket");
    const predictionMarket = await AIModelPredictionMarket.deploy();
    await predictionMarket.waitForDeployment();
    const predictionMarketAddress = await predictionMarket.getAddress();
    deployedContracts.AIModelPredictionMarket = predictionMarketAddress;
    contractABIs.AIModelPredictionMarket = AIModelPredictionMarket.interface.format('json');
    console.log(`✅ AIModelPredictionMarket: ${predictionMarketAddress}`);
    
    // 10. 部署联邦学习合约
    console.log("\n🤝 部署FederatedLearningCoordinator合约...");
    const FederatedLearningCoordinator = await ethers.getContractFactory("FederatedLearningCoordinator");
    const federatedLearning = await FederatedLearningCoordinator.deploy();
    await federatedLearning.waitForDeployment();
    const federatedLearningAddress = await federatedLearning.getAddress();
    deployedContracts.FederatedLearningCoordinator = federatedLearningAddress;
    contractABIs.FederatedLearningCoordinator = FederatedLearningCoordinator.interface.format('json');
    console.log(`✅ FederatedLearningCoordinator: ${federatedLearningAddress}`);
    
    // 11. 部署市场合约
    console.log("\n🏪 部署AIModelMarketplace合约...");
    const AIModelMarketplace = await ethers.getContractFactory("AIModelMarketplace");
    const marketplace = await AIModelMarketplace.deploy();
    await marketplace.waitForDeployment();
    const marketplaceAddress = await marketplace.getAddress();
    deployedContracts.AIModelMarketplace = marketplaceAddress;
    contractABIs.AIModelMarketplace = AIModelMarketplace.interface.format('json');
    console.log(`✅ AIModelMarketplace: ${marketplaceAddress}`);
    
    // 设置权限和初始化
    console.log("\n⚙️ 设置合约权限...");
    
    // 给保险合约设置代币权限
    const INSURANCE_ROLE = await aimtToken.INSURANCE_ROLE();
    await aimtToken.grantRole(INSURANCE_ROLE, insuranceAddress);
    console.log("✅ 保险合约权限设置完成");
    
    // 保存部署信息
    const deploymentInfo = {
      network: {
        name: network.name,
        chainId: Number(network.chainId),
        rpcUrl: "https://sepolia.infura.io/v3/315dbedded6b4b37a95b73281cb81e22"
      },
      deployer: {
        address: deployer.address,
        balance: ethers.formatEther(balance)
      },
      contracts: deployedContracts,
      deployedAt: new Date().toISOString(),
      gasUsed: "Estimated based on contract complexity"
    };
    
    // 写入部署地址文件
    fs.writeFileSync(
      'sepolia-contracts.json', 
      JSON.stringify(deploymentInfo, null, 2)
    );
    
    // 写入ABI文件
    fs.writeFileSync(
      'contract-abis.json',
      JSON.stringify(contractABIs, null, 2)
    );
    
    console.log("\n📋 Sepolia部署总结:");
    console.log("=".repeat(60));
    Object.entries(deployedContracts).forEach(([name, address]) => {
      console.log(`${name.padEnd(30)} : ${address}`);
    });
    
    console.log(`\n🌐 浏览器查看: https://sepolia.etherscan.io/address/${modelRegistryAddress}`);
    console.log("📁 部署信息已保存到 sepolia-contracts.json");
    console.log("📁 合约ABI已保存到 contract-abis.json");
    console.log("\n🎉 Sepolia测试网部署完成!");
    
  } catch (error) {
    console.error("❌ 部署失败:", error);
    throw error;
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
