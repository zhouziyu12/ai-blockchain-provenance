const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("统一代币生态系统测试", function () {
  let aimtToken, insurance;
  let owner, user1, user2, validator;

  beforeEach(async function () {
    [owner, user1, user2, validator] = await ethers.getSigners();

    // 部署统一代币合约
    const AIModelTokenV2 = await ethers.getContractFactory("AIModelTokenV2");
    aimtToken = await AIModelTokenV2.deploy();

    // 部署保险合约
    const AIModelInsuranceV2 = await ethers.getContractFactory("AIModelInsuranceV2");
    insurance = await AIModelInsuranceV2.deploy(await aimtToken.getAddress());

    // 设置权限
    await aimtToken.grantRole(await aimtToken.INSURANCE_ROLE(), await insurance.getAddress());
    await insurance.grantRole(await insurance.ASSESSOR_ROLE(), validator.address);

    // 给用户一些代币
    await aimtToken.transfer(user1.address, ethers.parseEther("100000"));
    await aimtToken.transfer(user2.address, ethers.parseEther("50000"));
  });

  describe("多类型质押测试", function () {
    it("应该支持模型开发质押", async function () {
      const poolId = 1; // MODEL_DEVELOPMENT pool
      const stakeAmount = ethers.parseEther("1000");
      const modelId = "test_model_001";

      await aimtToken.connect(user1).stakeTokens(poolId, stakeAmount, modelId);

      const userStake = await aimtToken.getUserStakeInfo(user1.address, poolId);
      expect(userStake.amount).to.equal(stakeAmount);

      const modelStake = await aimtToken.userModelStakes(user1.address, modelId);
      expect(modelStake).to.equal(stakeAmount);
    });

    it("应该支持保险流动性质押", async function () {
      const poolId = 2; // INSURANCE_LIQUIDITY pool
      const stakeAmount = ethers.parseEther("500");

      await aimtToken.connect(user1).stakeTokens(poolId, stakeAmount, "");

      const userStake = await aimtToken.getUserStakeInfo(user1.address, poolId);
      expect(userStake.amount).to.equal(stakeAmount);

      const [userLiquidity, totalFunds,] = await aimtToken.getInsuranceStats(user1.address);
      expect(userLiquidity).to.equal(stakeAmount);
      expect(totalFunds).to.equal(stakeAmount);
    });

    it("应该支持治理质押和权重计算", async function () {
      const poolId = 3; // GOVERNANCE pool
      const stakeAmount = ethers.parseEther("100");

      await aimtToken.connect(user1).stakeTokens(poolId, stakeAmount, "");

      const [weight, votingPower] = await aimtToken.getGovernanceInfo(user1.address);
      expect(weight).to.be.gt(0);
      expect(votingPower).to.equal(weight);
    });
  });

  describe("奖励系统测试", function () {
    it("应该正确计算和分发质押奖励", async function () {
      const poolId = 1;
      const stakeAmount = ethers.parseEther("1000");

      await aimtToken.connect(user1).stakeTokens(poolId, stakeAmount, "test_model");

      // 模拟时间流逝
      await ethers.provider.send("evm_increaseTime", [3600]); // 1小时
      await ethers.provider.send("evm_mine");

      const earned = await aimtToken.earned(user1.address, poolId);
      expect(earned).to.be.gt(0);

      await aimtToken.connect(user1).claimRewards(poolId);
      
      // 检查奖励是否发放
      const userStake = await aimtToken.getUserStakeInfo(user1.address, poolId);
      expect(userStake.rewards).to.equal(0); // 已领取
    });

    it("应该支持一键领取所有奖励", async function () {
      // 在多个池子质押
      await aimtToken.connect(user1).stakeTokens(1, ethers.parseEther("1000"), "model1");
      await aimtToken.connect(user1).stakeTokens(2, ethers.parseEther("500"), "");

      // 模拟时间流逝
      await ethers.provider.send("evm_increaseTime", [3600]);
      await ethers.provider.send("evm_mine");

      const balanceBefore = await aimtToken.balanceOf(user1.address);
      await aimtToken.connect(user1).claimAllRewards();
      const balanceAfter = await aimtToken.balanceOf(user1.address);

      expect(balanceAfter).to.be.gt(balanceBefore);
    });
  });

  describe("保险集成测试", function () {
    it("应该创建保险单并处理理赔", async function () {
      // 先添加保险流动性
      await aimtToken.connect(user2).stakeTokens(2, ethers.parseEther("10000"), "");

      // 批准保险费
      const coverageAmount = ethers.parseEther("1000");
      const [premium,] = await insurance.calculatePremium("test_model", 0, coverageAmount, 90 * 24 * 3600);
      
      await aimtToken.connect(user1).approve(await insurance.getAddress(), premium);

      // 创建保险单
      await insurance.connect(user1).createPolicy(
        "test_model",
        0, // PERFORMANCE_GUARANTEE
        coverageAmount,
        90 * 24 * 3600,
        ethers.parseEther("100"),
        ethers.keccak256(ethers.toUtf8Bytes("terms"))
      );

      const policy = await insurance.getPolicy(1);
      expect(policy.policyholder).to.equal(user1.address);
      expect(policy.coverageAmount).to.equal(coverageAmount);
    });
  });

  describe("生态系统统计", function () {
    it("应该提供完整的生态系统数据", async function () {
      // 进行一些质押操作
      await aimtToken.connect(user1).stakeTokens(1, ethers.parseEther("1000"), "model1");
      await aimtToken.connect(user2).stakeTokens(2, ethers.parseEther("2000"), "");

      const [totalSupply, circulatingSupply, totalStaked, totalRewardsDistributed, protocolRevenue] = 
        await aimtToken.getEcosystemStats();

      expect(totalSupply).to.equal(ethers.parseEther("1000000000"));
      expect(totalStaked).to.equal(ethers.parseEther("3000"));
      expect(circulatingSupply).to.be.gt(0);
    });
  });
});
