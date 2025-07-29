const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("完整AI模型溯源系统测试", function () {
  let aiModelRegistry, trainingDataManager, deploymentManager, auditManager, aiModelNFT, aiModelTokenV2, marketplace;
  let owner, creator, auditor, user1, user2;

  beforeEach(async function () {
    [owner, creator, auditor, user1, user2] = await ethers.getSigners();

    // 部署所有合约
    const AIModelRegistry = await ethers.getContractFactory("AIModelRegistry");
    aiModelRegistry = await AIModelRegistry.deploy();

    const TrainingDataManager = await ethers.getContractFactory("TrainingDataManager");
    trainingDataManager = await TrainingDataManager.deploy();

    const DeploymentManager = await ethers.getContractFactory("DeploymentManager");
    deploymentManager = await DeploymentManager.deploy();

    const AuditManager = await ethers.getContractFactory("AuditManager");
    auditManager = await AuditManager.deploy();

    const AIModelNFT = await ethers.getContractFactory("AIModelNFT");
    aiModelNFT = await AIModelNFT.deploy();

    const AIModelTokenV2 = await ethers.getContractFactory("AIModelTokenV2");
    aiModelTokenV2 = await AIModelTokenV2.deploy();

    const AIModelMarketplace = await ethers.getContractFactory("AIModelMarketplace");
    marketplace = await AIModelMarketplace.deploy();

    // 设置角色
    await aiModelRegistry.grantRole(await aiModelRegistry.MODEL_CREATOR_ROLE(), creator.address);
    await auditManager.grantRole(await auditManager.AUDITOR_ROLE(), auditor.address);
    await trainingDataManager.grantRole(await trainingDataManager.DATA_MANAGER_ROLE(), creator.address);
    await deploymentManager.grantRole(await deploymentManager.DEPLOYER_ROLE(), creator.address);
    await aiModelNFT.grantRole(await aiModelNFT.MINTER_ROLE(), creator.address);
  });

  describe("完整工作流程测试", function () {
    it("应该完成从注册到市场销售的完整流程", async function () {
      const modelId = "ai_model_001";
      
      // 1. 注册模型
      await aiModelRegistry.connect(creator).registerModel(
        modelId,
        "图像分类模型",
        "v1.0.0",
        0, // CLASSIFICATION
        "CNN"
      );

      // 2. 添加训练数据
      await trainingDataManager.connect(creator).addTrainingData(
        modelId,
        ethers.keccak256(ethers.toUtf8Bytes("dataset1")),
        "CIFAR-10",
        0, // TRAINING
        50000,
        "Kaggle",
        "normalization",
        ethers.keccak256(ethers.toUtf8Bytes("labels1"))
      );

      // 3. 更新模型指标
      await aiModelRegistry.connect(creator).updateModelMetrics(
        modelId,
        9500, // 95% accuracy
        9200, // 92% precision
        9300, // 93% recall
        3600  // 1 hour training time
      );

      // 4. 审计模型
      await auditManager.connect(auditor).auditModel(
        modelId,
        "模型表现良好，无安全问题",
        85,
        true,
        "ISO-27001"
      );

      // 5. 创建NFT
      await aiModelNFT.connect(creator).mintModelNFT(
        creator.address,
        modelId,
        "图像分类模型",
        "v1.0.0",
        9500,
        "QmHash123"
      );

      // 6. 在市场上列出模型
      await marketplace.connect(creator).listModel(
        modelId,
        ethers.parseEther("0.1"), // 0.1 ETH per use
        ethers.parseEther("1.0"),  // 1 ETH per month subscription
        0, // TEMPORARY
        10, // 10 uses
        86400, // 24 hours
        "高精度图像分类模型",
        ["AI", "Computer Vision", "Classification"]
      );

      // 7. 用户购买访问权限
      await marketplace.connect(user1).purchaseAccess(
        1, // listingId
        0, // TEMPORARY access
        { value: ethers.parseEther("0.1") }
      );

      // 8. 验证购买成功
      const hasAccess = await marketplace.hasAccess(user1.address, modelId);
      expect(hasAccess).to.be.true;

      // 9. 使用模型
      await marketplace.connect(user1).useModel(
        modelId,
        ethers.keccak256(ethers.toUtf8Bytes("input_data")),
        ethers.keccak256(ethers.toUtf8Bytes("output_result"))
      );

      // 10. 验证模型被使用
      const [totalUsages, uniqueUsers, recentUsages] = await marketplace.getModelUsageStats(modelId);
      expect(totalUsages).to.equal(1);
      expect(uniqueUsers).to.equal(1);
    });

    it("应该正确处理代币质押和奖励", async function () {
      const modelId = "token_model_001";
      
      // 注册模型
      await aiModelRegistry.connect(creator).registerModel(
        modelId,
        "代币测试模型",
        "v1.0.0",
        1, // REGRESSION
        "Linear Regression"
      );

      // 给用户一些代币
      await aiModelTokenV2.transfer(user1.address, ethers.parseEther("10000"));
      
      // 用户质押代币
      await aiModelTokenV2.connect(user1).stakeTokens(
        1, // MODEL_DEVELOPMENT pool
        ethers.parseEther("1000"),
        modelId
      );

      // 验证质押信息
      const userStake = await aiModelTokenV2.getUserStakeInfo(user1.address, 1);
      expect(userStake.amount).to.equal(ethers.parseEther("1000"));
    });
  });

  describe("安全性测试", function () {
    it("应该防止未授权的模型操作", async function () {
      const modelId = "security_test_001";
      
      // 非创建者尝试注册模型应该失败
      await expect(
        aiModelRegistry.connect(user1).registerModel(
          modelId,
          "未授权模型",
          "v1.0.0",
          0,
          "CNN"
        )
      ).to.be.reverted;
    });

    it("应该防止重复的模型注册", async function () {
      const modelId = "duplicate_test_001";
      
      // 第一次注册
      await aiModelRegistry.connect(creator).registerModel(
        modelId,
        "原始模型",
        "v1.0.0",
        0,
        "CNN"
      );

      // 第二次注册应该失败
      await expect(
        aiModelRegistry.connect(creator).registerModel(
          modelId,
          "重复模型",
          "v2.0.0",
          0,
          "RNN"
        )
      ).to.be.revertedWith("Model already exists");
    });
  });
});
