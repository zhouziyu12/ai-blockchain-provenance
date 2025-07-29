const { ethers } = require("hardhat");

async function main() {
  console.log("💰 Sepolia测试币获取指南");
  console.log("=" .repeat(50));
  
  const [deployer] = await ethers.getSigners();
  console.log(`部署账户: ${deployer.address}`);
  
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log(`当前余额: ${ethers.formatEther(balance)} ETH`);
  
  if (Number(balance) < ethers.parseEther("0.1")) {
    console.log("\n❌ 余额不足，需要获取测试币!");
    console.log("\n🚰 Sepolia测试币水龙头:");
    console.log("1. https://sepoliafaucet.com/");
    console.log("2. https://www.alchemy.com/faucets/ethereum-sepolia");
    console.log("3. https://faucets.chain.link/sepolia");
    console.log("4. https://sepolia-faucet.pk910.de/");
    
    console.log(`\n📋 使用地址: ${deployer.address}`);
    console.log("💡 建议获取至少 0.5 ETH 用于合约部署");
  } else {
    console.log("✅ 余额充足，可以开始部署!");
  }
}

main().catch(console.error);
