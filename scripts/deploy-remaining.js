const { ethers } = require("hardhat");
const fs = require('fs');

async function main() {
  console.log("🚀 部署剩余的2个合约...");
  
  const [deployer] = await ethers.getSigners();
  console.log(`部署账户: ${deployer.address}`);
  
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log(`当前余额: ${ethers.formatEther(balance)} ETH`);
  
  if (Number(balance) < ethers.parseEther("0.1")) {
    console.error("❌ 余额不足！请先获取更多测试币");
    return;
  }
  
  // 读取已部署的合约
  const deployed = JSON.parse(fs.readFileSync('sepolia-contracts-partial.json', 'utf8'));
  
  try {
    // 10. 部署联邦学习合约
    console.log("\n🤝 部署FederatedLearningCoordinator合约...");
    const FederatedLearningCoordinator = await ethers.getContractFactory("FederatedLearningCoordinator");
    const federatedLearning = await FederatedLearningCoordinator.deploy();
    await federatedLearning.waitForDeployment();
    const federatedLearningAddress = await federatedLearning.getAddress();
    deployed.contracts.FederatedLearningCoordinator = federatedLearningAddress;
    console.log(`✅ FederatedLearningCoordinator: ${federatedLearningAddress}`);
    
    // 11. 部署市场合约
    console.log("\n🏪 部署AIModelMarketplace合约...");
    const AIModelMarketplace = await ethers.getContractFactory("AIModelMarketplace");
    const marketplace = await AIModelMarketplace.deploy();
    await marketplace.waitForDeployment();
    const marketplaceAddress = await marketplace.getAddress();
    deployed.contracts.AIModelMarketplace = marketplaceAddress;
    console.log(`✅ AIModelMarketplace: ${marketplaceAddress}`);
    
    // 更新部署信息
    deployed.pending = [];
    deployed.status = "完全部署";
    deployed.completedAt = new Date().toISOString();
    
    // 保存完整的部署信息
    fs.writeFileSync('sepolia-contracts.json', JSON.stringify(deployed, null, 2));
    
    console.log("\n🎉 所有合约部署完成!");
    console.log("📁 完整部署信息已保存到 sepolia-contracts.json");
    
  } catch (error) {
    console.error("❌ 部署失败:", error.message);
  }
}

main().catch(console.error);
