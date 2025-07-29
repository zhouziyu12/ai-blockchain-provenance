const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("AIModelRegistry", function () {
  let aiModelRegistry;
  let owner;
  let user1;
  let user2;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();
    
    const AIModelRegistry = await ethers.getContractFactory("AIModelRegistry");
    aiModelRegistry = await AIModelRegistry.deploy();
    
    // 给用户权限
    await aiModelRegistry.grantRole(await aiModelRegistry.MODEL_CREATOR_ROLE(), user1.address);
  });

  describe("模型注册功能", function () {
    it("应该成功注册新模型", async function () {
      const modelId = "model_001";
      const modelName = "图像分类模型";
      const version = "v1.0.0";
      const algorithm = "CNN";

      await expect(
        aiModelRegistry.connect(user1).registerModel(
          modelId,
          modelName,
          version,
          0, // CLASSIFICATION
          algorithm
        )
      ).to.emit(aiModelRegistry, "ModelRegistered");

      const model = await aiModelRegistry.getModel(modelId);
      expect(model.modelId).to.equal(modelId);
      expect(model.modelName).to.equal(modelName);
      expect(model.creator).to.equal(user1.address);
    });

    it("应该拒绝重复的模型ID", async function () {
      const modelId = "model_001";
      
      // 第一次注册
      await aiModelRegistry.connect(user1).registerModel(
        modelId,
        "模型1",
        "v1.0.0",
        0, // CLASSIFICATION
        "CNN"
      );

      // 第二次注册应该失败
      await expect(
        aiModelRegistry.connect(user1).registerModel(
          modelId,
          "模型2",
          "v2.0.0",
          1, // REGRESSION
          "RNN"
        )
      ).to.be.revertedWith("Model already exists");
    });
  });

  describe("完整性验证", function () {
    beforeEach(async function () {
      await aiModelRegistry.connect(user1).registerModel(
        "model_001",
        "测试模型",
        "v1.0.0",
        0, // CLASSIFICATION
        "CNN"
      );
    });

    it("应该验证模型完整性", async function () {
      const [isValid, storedHash, calculatedHash] = await aiModelRegistry.verifyIntegrity("model_001");
      
      expect(isValid).to.be.true;
      expect(storedHash).to.equal(calculatedHash);
    });
  });

  describe("模型更新", function () {
    beforeEach(async function () {
      await aiModelRegistry.connect(user1).registerModel(
        "model_001",
        "测试模型",
        "v1.0.0",
        0, // CLASSIFICATION
        "CNN"
      );
    });

    it("应该成功更新模型指标", async function () {
      await expect(
        aiModelRegistry.connect(user1).updateModelMetrics(
          "model_001",
          9500, // 95% accuracy
          9200, // 92% precision
          9300, // 93% recall
          3600  // 1 hour training time
        )
      ).to.emit(aiModelRegistry, "MetricsUpdated");

      const metrics = await aiModelRegistry.getModelMetrics("model_001");
      expect(metrics.accuracy).to.equal(9500);
    });

    it("只有创建者可以更新模型", async function () {
      await expect(
        aiModelRegistry.connect(user2).updateModelMetrics(
          "model_001",
          9000,
          8500,
          8800,
          7200
        )
      ).to.be.revertedWith("Only creator allowed");
    });
  });
});
