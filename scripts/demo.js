const { ethers } = require("hardhat");

async function main() {
  console.log("🎬 AI模型溯源系统演示开始");
  console.log("=" .repeat(50));
  
  // 读取已部署的合约地址
  const fs = require('fs');
  const addresses = JSON.parse(fs.readFileSync('deployed-contracts.json', 'utf8'));
  
  const [owner, creator, user, auditor] = await ethers.getSigners();
  
  console.log("\n👥 演示参与者:");
  console.log(`Owner: ${owner.address}`);
  console.log(`Creator: ${creator.address}`);
  console.log(`User: ${user.address}`);
  console.log(`Auditor: ${auditor.address}`);
  
  // 连接合约
  const modelRegistry = await ethers.getContractAt("AIModelRegistry", addresses.AIModelRegistry);
  const aimtToken = await ethers.getContractAt("AIModelTokenV2", addresses.AIModelTokenV2);
  const insurance = await ethers.getContractAt("AIModelInsuranceV2", addresses.AIModelInsuranceV2);
  const marketplace = await ethers.getContractAt("AIModelMarketplace", addresses.AIModelMarketplace);
  const modelNFT = await ethers.getContractAt("AIModelNFT", addresses.AIModelNFT);
  const auditManager = await ethers.getContractAt("AuditManager", addresses.AuditManager);
  
  console.log("\n🔗 已连接到所有合约");
  
  try {
    // 生成唯一模型ID
    const timestamp = Date.now();
    const modelId = `demo_ai_model_${timestamp}`;
    
    // 1. 设置角色权限
    console.log("\n⚙️ 步骤1: 设置角色权限");
    await modelRegistry.grantRole(await modelRegistry.MODEL_CREATOR_ROLE(), creator.address);
    await auditManager.grantRole(await auditManager.AUDITOR_ROLE(), auditor.address);
    await modelNFT.grantRole(await modelNFT.MINTER_ROLE(), creator.address);
    console.log("✅ 角色权限设置完成");
    
    // 2. 分发代币
    console.log("\n💰 步骤2: 分发AIMT代币");
    await aimtToken.transfer(creator.address, ethers.parseEther("50000"));
    await aimtToken.transfer(user.address, ethers.parseEther("30000"));
    console.log("✅ 代币分发完成");
    
    // 3. 注册AI模型
    console.log("\n📝 步骤3: 注册AI模型");
    await modelRegistry.connect(creator).registerModel(
      modelId,
      "高精度图像分类模型",
      "v1.0.0",
      0, // CLASSIFICATION
      "ResNet-50"
    );
    console.log(`✅ 模型 ${modelId} 注册成功`);
    
    // 4. 更新模型性能指标
    console.log("\n📊 步骤4: 更新模型性能指标");
    await modelRegistry.connect(creator).updateModelMetrics(
      modelId,
      9650, // 96.5% accuracy
      9580, // 95.8% precision  
      9720, // 97.2% recall
      7200  // 2 hours training time
    );
    console.log("✅ 性能指标更新完成");
    
    // 5. 第三方审计
    console.log("\n🔍 步骤5: 第三方模型审计");
    await auditManager.connect(auditor).auditModel(
      modelId,
      "模型架构合理，性能指标真实，无安全漏洞",
      92, // 92分
      true, // 通过审计
      "AI-SEC-2024-001"
    );
    console.log("✅ 审计完成，模型获得92分认证");
    
    // 6. 创建NFT
    console.log("\n🎨 步骤6: 铸造模型NFT");
    await modelNFT.connect(creator).mintModelNFT(
      creator.address,
      modelId,
      "高精度图像分类模型",
      "v1.0.0",
      9650,
      "QmABC123...DeF456" // IPFS hash
    );
    console.log("✅ 模型NFT铸造成功");
    
    // 7. 质押代币获得保险流动性
    console.log("\n🛡️ 步骤7: 提供保险流动性");
    await aimtToken.connect(user).stakeTokens(
      2, // INSURANCE_LIQUIDITY pool
      ethers.parseEther("10000"),
      ""
    );
    console.log("✅ 用户提供了10,000 AIMT保险流动性");
    
    // 8. 购买模型保险
    console.log("\n📋 步骤8: 购买模型保险");
    const coverageAmount = ethers.parseEther("5000");
    const [premium] = await insurance.calculatePremium(
      modelId, 
      0, // PERFORMANCE_GUARANTEE
      coverageAmount, 
      90 * 24 * 3600 // 90天
    );
    
    await aimtToken.connect(creator).approve(addresses.AIModelInsuranceV2, premium);
    await insurance.connect(creator).createPolicy(
      modelId,
      0,
      coverageAmount,
      90 * 24 * 3600,
      ethers.parseEther("500"), // 免赔额
      ethers.keccak256(ethers.toUtf8Bytes("performance_guarantee_terms"))
    );
    console.log(`✅ 保险购买成功，保额: ${ethers.formatEther(coverageAmount)} AIMT`);
    console.log(`   保费: ${ethers.formatEther(premium)} AIMT`);
    
    // 9. 模型市场上架
    console.log("\n🏪 步骤9: 模型市场上架");
    await marketplace.connect(creator).listModel(
      modelId,
      ethers.parseEther("0.1"), // 每次使用0.1 ETH
      ethers.parseEther("2.0"),  // 月订阅2 ETH
      0, // TEMPORARY access
      50, // 50次使用限制
      30 * 24 * 3600, // 30天有效期
      "企业级图像分类AI模型，96.5%准确率，通过权威审计",
      ["AI", "Computer Vision", "Classification", "Enterprise"]
    );
    console.log("✅ 模型已上架到市场");
    
    // 获取listing信息来确认modelId
    const listing = await marketplace.getListing(1);
    console.log(`   上架模型ID: ${listing.modelId}`);
    
    // 10. 用户购买使用权
    console.log("\n🛒 步骤10: 用户购买模型使用权");
    await marketplace.connect(user).purchaseAccess(
      1, // listingId
      0, // TEMPORARY access
      { value: ethers.parseEther("0.1") }
    );
    console.log("✅ 用户购买了临时使用权");
    
    // 验证用户是否有访问权限
    const hasAccess = await marketplace.hasAccess(user.address, listing.modelId);
    console.log(`   用户访问权限: ${hasAccess ? '有效' : '无效'}`);
    
    // 获取用户访问详情
    const userAccess = await marketplace.getUserAccess(user.address, listing.modelId);
    console.log(`   剩余使用次数: ${Number(userAccess.usagesRemaining)}`);
    console.log(`   访问状态: ${userAccess.isActive ? '激活' : '未激活'}`);
    
    // 11. 使用模型（使用listing中的modelId）
    console.log("\n🤖 步骤11: 使用AI模型");
    if (hasAccess) {
      await marketplace.connect(user).useModel(
        listing.modelId, // 使用listing中的modelId
        ethers.keccak256(ethers.toUtf8Bytes("input_image_data")),
        ethers.keccak256(ethers.toUtf8Bytes("classification_result"))
      );
      console.log("✅ 模型使用成功");
    } else {
      console.log("❌ 用户没有访问权限，跳过模型使用");
    }
    
    // 12. 查看系统状态
    console.log("\n📊 步骤12: 系统状态总览");
    const model = await modelRegistry.getModel(modelId);
    const metrics = await modelRegistry.getModelMetrics(modelId);
    const [totalSupply_, circulating, totalStaked, totalRewardsDistributed_, protocolRevenue_] = await aimtToken.getEcosystemStats();
    const [userLiquidity, totalInsuranceFunds] = await aimtToken.getInsuranceStats(user.address);
    const [totalUsages, uniqueUsers] = await marketplace.getModelUsageStats(listing.modelId);
    
    console.log("\n📈 生态系统数据:");
    console.log(`模型状态: ${getStatusName(Number(model.status))}`);
    console.log(`模型精度: ${Number(metrics.accuracy) / 100}%`);
    console.log(`AIMT总供应: ${ethers.formatEther(totalSupply_)}`);
    console.log(`流通量: ${ethers.formatEther(circulating)}`);
    console.log(`总质押量: ${ethers.formatEther(totalStaked)}`);
    console.log(`保险资金池: ${ethers.formatEther(totalInsuranceFunds)} AIMT`);
    console.log(`模型总使用次数: ${Number(totalUsages)}`);
    console.log(`独立用户数: ${Number(uniqueUsers)}`);
    
    // 13. 额外展示：查看模型审计信息
    console.log("\n🔍 审计信息:");
    const audits = await auditManager.getModelAudits(modelId);
    if (audits.length > 0) {
      const latestAudit = audits[0];
      console.log(`审计分数: ${Number(latestAudit.score)}/100`);
      console.log(`审计结果: ${latestAudit.approved ? '通过' : '未通过'}`);
      console.log(`认证编号: ${latestAudit.certification}`);
    }
    
    // 14. 展示NFT信息
    console.log("\n🎨 NFT信息:");
    const nftMetadata = await modelNFT.getModelNFTMetadata(1);
    console.log(`NFT模型: ${nftMetadata.modelName}`);
    console.log(`NFT版本: ${nftMetadata.version}`);
    console.log(`NFT创建者: ${nftMetadata.creator}`);
    
    // 15. 演示用户质押挖矿奖励
    console.log("\n💎 步骤15: 质押挖矿奖励演示");
    
    // 模拟时间流逝（在实际区块链上需要等待）
    console.log("   模拟时间流逝...");
    
    // 查看用户在保险池的奖励
    const earnedRewards = await aimtToken.earned(user.address, 2); // INSURANCE_LIQUIDITY pool
    console.log(`   用户待领取奖励: ${ethers.formatEther(earnedRewards)} AIMT`);
    
    if (earnedRewards > 0) {
      await aimtToken.connect(user).claimRewards(2);
      console.log("✅ 用户成功领取质押奖励");
    }
    
    console.log("\n🎉 演示完成!");
    console.log("=" .repeat(50));
    console.log("🚀 AI模型溯源生态系统运行成功!");
    console.log("💡 这个演示展示了从AI模型创建到商业化的完整生命周期");
    console.log("🔗 所有操作都记录在区块链上，确保透明度和可追溯性");
    console.log(`📝 演示模型ID: ${modelId}`);
    console.log(`🏪 市场模型ID: ${listing.modelId}`);
    
    // 16. 生成演示报告
    const report = {
      registryModelId: modelId,
      marketplaceModelId: listing.modelId,
      modelName: "高精度图像分类模型",
      accuracy: Number(metrics.accuracy) / 100,
      auditScore: audits.length > 0 ? Number(audits[0].score) : 0,
      insuranceCoverage: ethers.formatEther(coverageAmount),
      usageCount: Number(totalUsages),
      nftTokenId: 1,
      userHasAccess: hasAccess,
      totalStaked: ethers.formatEther(totalStaked),
      timestamp: new Date().toISOString()
    };
    
    fs.writeFileSync('demo-report.json', JSON.stringify(report, null, 2));
    console.log("📊 演示报告已保存到 demo-report.json");
    
  } catch (error) {
    console.error("❌ 演示过程中发生错误:", error.message);
    console.error("详细错误:", error);
  }
}

function getStatusName(status) {
  const statusNames = ["REGISTERED", "TRAINING", "VALIDATED", "DEPLOYED", "DEPRECATED"];
  return statusNames[status] || "UNKNOWN";
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
