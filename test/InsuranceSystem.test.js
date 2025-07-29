const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("AI模型保险系统测试", function () {
  let insurance, aimtToken;
  let owner, policyholder, assessor, liquidityProvider;

  beforeEach(async function () {
    [owner, policyholder, assessor, liquidityProvider] = await ethers.getSigners();

    // 部署统一代币合约
    const AIModelTokenV2 = await ethers.getContractFactory("AIModelTokenV2");
    aimtToken = await AIModelTokenV2.deploy();

    // 部署保险合约
    const AIModelInsuranceV2 = await ethers.getContractFactory("AIModelInsuranceV2");
    insurance = await AIModelInsuranceV2.deploy(await aimtToken.getAddress());

    // 设置权限
    await aimtToken.grantRole(await aimtToken.INSURANCE_ROLE(), await insurance.getAddress());
    await insurance.grantRole(await insurance.ASSESSOR_ROLE(), assessor.address);

    // 给用户代币
    await aimtToken.transfer(policyholder.address, ethers.parseEther("50000"));
    await aimtToken.transfer(liquidityProvider.address, ethers.parseEther("100000"));
  });

  describe("保险购买和理赔流程", function () {
    it("应该成功创建保险单", async function () {
      const modelId = "test_model_001";
      const coverageAmount = ethers.parseEther("10");
      const duration = 90 * 24 * 60 * 60; // 90天
      
      // 添加流动性到风险池
      await aimtToken.connect(liquidityProvider).stakeTokens(
        2, // INSURANCE_LIQUIDITY pool
        ethers.parseEther("50000"),
        ""
      );

      // 计算保险费
      const [premium] = await insurance.calculatePremium(modelId, 0, coverageAmount, duration);
      
      // 批准保险费支付
      await aimtToken.connect(policyholder).approve(await insurance.getAddress(), premium);
      
      // 创建保险单
      await expect(
        insurance.connect(policyholder).createPolicy(
          modelId,
          0, // PERFORMANCE_GUARANTEE
          coverageAmount,
          duration,
          ethers.parseEther("1"), // 免赔额
          ethers.keccak256(ethers.toUtf8Bytes("terms"))
        )
      ).to.emit(insurance, "PolicyCreated");

      const policy = await insurance.getPolicy(1);
      expect(policy.modelId).to.equal(modelId);
      expect(policy.policyholder).to.equal(policyholder.address);
      expect(policy.coverageAmount).to.equal(coverageAmount);
    });

    it("应该处理完整的理赔流程", async function () {
      const modelId = "claim_test_model";
      const coverageAmount = ethers.parseEther("5");
      const duration = 30 * 24 * 60 * 60;
      
      // 添加流动性
      await aimtToken.connect(liquidityProvider).stakeTokens(
        2, // INSURANCE_LIQUIDITY pool
        ethers.parseEther("20000"),
        ""
      );

      // 创建保险单
      const [premium] = await insurance.calculatePremium(modelId, 0, coverageAmount, duration);
      await aimtToken.connect(policyholder).approve(await insurance.getAddress(), premium);
      
      await insurance.connect(policyholder).createPolicy(
        modelId, 0, coverageAmount, duration,
        ethers.parseEther("0.5"),
        ethers.keccak256(ethers.toUtf8Bytes("terms"))
      );

      // 提交理赔申请
      const claimAmount = ethers.parseEther("3");
      await expect(
        insurance.connect(policyholder).submitClaim(
          1, // policyId
          claimAmount,
          "模型性能低于承诺指标",
          "evidence_hash_123"
        )
      ).to.emit(insurance, "ClaimSubmitted");

      // 评估理赔
      await expect(
        insurance.connect(assessor).assessClaim(
          1, // claimId
          1, // APPROVED
          "经评估，理赔申请属实"
        )
      ).to.emit(insurance, "ClaimPaid");

      const claim = await insurance.getClaim(1);
      expect(claim.status).to.equal(3); // PAID
    });
  });

  describe("风险评估", function () {
    it("应该根据模型类型调整风险评分", async function () {
      const modelId = "risk_test_model";
      const coverageAmount = ethers.parseEther("1");
      const duration = 30 * 24 * 60 * 60;

      // 测试不同保险类型的风险评分
      const [premium1] = await insurance.calculatePremium(modelId, 0, coverageAmount, duration); // PERFORMANCE
      const [premium2] = await insurance.calculatePremium(modelId, 1, coverageAmount, duration); // DATA_BREACH
      const [premium3] = await insurance.calculatePremium(modelId, 2, coverageAmount, duration); // DEPLOYMENT

      // 数据泄露保险应该有更高的保险费
      expect(premium2).to.be.gt(premium1);
    });
  });
});
