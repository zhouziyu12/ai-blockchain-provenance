// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract AIModelInsurance is AccessControl, ReentrancyGuard {
    
    bytes32 public constant INSURER_ROLE = keccak256("INSURER_ROLE");
    bytes32 public constant ASSESSOR_ROLE = keccak256("ASSESSOR_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    
    enum InsuranceType { 
        PERFORMANCE_GUARANTEE,  // 性能保证保险
        DATA_BREACH,           // 数据泄露保险
        DEPLOYMENT_FAILURE,    // 部署失败保险
        REVENUE_PROTECTION,    // 收益保护保险
        COMPLIANCE_RISK       // 合规风险保险
    }
    
    enum PolicyStatus { ACTIVE, CLAIMED, EXPIRED, CANCELLED }
    enum ClaimStatus { PENDING, APPROVED, REJECTED, PAID }
    
    struct InsurancePolicy {
        uint256 policyId;
        string modelId;
        address policyholder;
        InsuranceType insuranceType;
        uint256 coverageAmount;      // 保险金额
        uint256 premium;             // 保险费
        uint256 deductible;          // 免赔额
        uint256 startTime;
        uint256 endTime;
        PolicyStatus status;
        bytes32 termsHash;           // 保险条款哈希
        uint256 riskScore;           // 风险评分 (0-1000)
    }
    
    struct Claim {
        uint256 claimId;
        uint256 policyId;
        address claimant;
        string description;
        uint256 claimAmount;
        ClaimStatus status;
        uint256 submitTime;
        uint256 assessmentTime;
        address assessor;
        string evidenceHash;         // 证据文件哈希
        string assessmentReport;
    }
    
    struct RiskPool {
        InsuranceType poolType;
        uint256 totalFunds;
        uint256 availableFunds;
        uint256 totalClaims;
        uint256 activePolicies;
        uint256 baseRate;            // 基础费率 (basis points)
        mapping(address => uint256) liquidityProviders;
        mapping(address => uint256) rewardDebt;
    }
    
    mapping(uint256 => InsurancePolicy) public policies;
    mapping(uint256 => Claim) public claims;
    mapping(InsuranceType => RiskPool) public riskPools;
    mapping(string => uint256[]) public modelPolicies;
    mapping(address => uint256[]) public userPolicies;
    mapping(address => uint256) public userRewards;
    
    uint256 public nextPolicyId = 1;
    uint256 public nextClaimId = 1;
    uint256 public totalTVL;                    // Total Value Locked
    uint256 public protocolFeeRate = 300;      // 3% protocol fee
    uint256 public liquidityRewardRate = 500;  // 5% APY for liquidity providers
    
    event PolicyCreated(uint256 indexed policyId, string modelId, address indexed policyholder, InsuranceType insuranceType, uint256 coverageAmount);
    event PremiumPaid(uint256 indexed policyId, address indexed policyholder, uint256 amount);
    event ClaimSubmitted(uint256 indexed claimId, uint256 indexed policyId, address indexed claimant, uint256 amount);
    event ClaimAssessed(uint256 indexed claimId, ClaimStatus status, address indexed assessor);
    event ClaimPaid(uint256 indexed claimId, address indexed claimant, uint256 amount);
    event LiquidityAdded(address indexed provider, InsuranceType poolType, uint256 amount);
    event LiquidityRemoved(address indexed provider, InsuranceType poolType, uint256 amount);
    event RewardsDistributed(address indexed provider, uint256 amount);
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(INSURER_ROLE, msg.sender);
        _grantRole(ASSESSOR_ROLE, msg.sender);
        _grantRole(ORACLE_ROLE, msg.sender);
        
        // 初始化风险池
        for (uint i = 0; i < 5; i++) {
            riskPools[InsuranceType(i)].poolType = InsuranceType(i);
            riskPools[InsuranceType(i)].baseRate = 500 + i * 200; // 5-13% base rate
        }
    }
    
    function calculatePremium(
        string memory _modelId,
        InsuranceType _type,
        uint256 _coverageAmount,
        uint256 _duration
    ) public view returns (uint256 premium, uint256 riskScore) {
        // 基础风险评分计算
        riskScore = calculateRiskScore(_modelId, _type);
        
        // 保险费计算：基础费率 + 风险调整 + 时间调整
        uint256 baseRate = riskPools[_type].baseRate;
        uint256 riskAdjustment = (riskScore * 500) / 1000; // 最大50%风险调整
        uint256 timeAdjustment = (_duration * 100) / 365 days; // 时间调整
        
        uint256 totalRate = baseRate + riskAdjustment + timeAdjustment;
        premium = (_coverageAmount * totalRate) / 10000;
    }
    
    function calculateRiskScore(string memory _modelId, InsuranceType _type) internal pure returns (uint256) {
        // 简化的风险评分算法
        bytes32 modelHash = keccak256(bytes(_modelId));
        uint256 baseScore = uint256(modelHash) % 500; // 0-499 base score
        
        // 根据保险类型调整风险评分
        if (_type == InsuranceType.PERFORMANCE_GUARANTEE) {
            baseScore += 100;
        } else if (_type == InsuranceType.DATA_BREACH) {
            baseScore += 200;
        } else if (_type == InsuranceType.DEPLOYMENT_FAILURE) {
            baseScore += 150;
        }
        
        return baseScore > 1000 ? 1000 : baseScore;
    }
    
    function createPolicy(
        string memory _modelId,
        InsuranceType _insuranceType,
        uint256 _coverageAmount,
        uint256 _duration,
        uint256 _deductible,
        bytes32 _termsHash
    ) external payable nonReentrant returns (uint256) {
        require(_coverageAmount > 0, "Coverage amount must be > 0");
        require(_duration >= 30 days, "Minimum 30 days coverage");
        require(_duration <= 365 days, "Maximum 365 days coverage");
        
        (uint256 premium, uint256 riskScore) = calculatePremium(_modelId, _insuranceType, _coverageAmount, _duration);
        require(msg.value >= premium, "Insufficient premium payment");
        
        // 检查风险池是否有足够资金
        require(riskPools[_insuranceType].availableFunds >= _coverageAmount, "Insufficient pool funds");
        
        uint256 policyId = nextPolicyId++;
        
        policies[policyId] = InsurancePolicy({
            policyId: policyId,
            modelId: _modelId,
            policyholder: msg.sender,
            insuranceType: _insuranceType,
            coverageAmount: _coverageAmount,
            premium: premium,
            deductible: _deductible,
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            status: PolicyStatus.ACTIVE,
            termsHash: _termsHash,
            riskScore: riskScore
        });
        
        // 更新风险池
        riskPools[_insuranceType].availableFunds -= _coverageAmount;
        riskPools[_insuranceType].activePolicies++;
        
        // 分配保险费
        uint256 protocolFee = (premium * protocolFeeRate) / 10000;
        uint256 poolContribution = premium - protocolFee;
        
        riskPools[_insuranceType].totalFunds += poolContribution;
        userRewards[address(this)] += protocolFee;
        
        // 更新映射
        modelPolicies[_modelId].push(policyId);
        userPolicies[msg.sender].push(policyId);
        
        // 退还多余的以太币
        if (msg.value > premium) {
            payable(msg.sender).transfer(msg.value - premium);
        }
        
        emit PolicyCreated(policyId, _modelId, msg.sender, _insuranceType, _coverageAmount);
        emit PremiumPaid(policyId, msg.sender, premium);
        
        return policyId;
    }
    
    function submitClaim(
        uint256 _policyId,
        uint256 _claimAmount,
        string memory _description,
        string memory _evidenceHash
    ) external returns (uint256) {
        InsurancePolicy storage policy = policies[_policyId];
        require(policy.policyholder == msg.sender, "Not policy holder");
        require(policy.status == PolicyStatus.ACTIVE, "Policy not active");
        require(block.timestamp <= policy.endTime, "Policy expired");
        require(_claimAmount <= policy.coverageAmount, "Claim exceeds coverage");
        require(_claimAmount >= policy.deductible, "Claim below deductible");
        
        uint256 claimId = nextClaimId++;
        
        claims[claimId] = Claim({
            claimId: claimId,
            policyId: _policyId,
            claimant: msg.sender,
            description: _description,
            claimAmount: _claimAmount,
            status: ClaimStatus.PENDING,
            submitTime: block.timestamp,
            assessmentTime: 0,
            assessor: address(0),
            evidenceHash: _evidenceHash,
            assessmentReport: ""
        });
        
        emit ClaimSubmitted(claimId, _policyId, msg.sender, _claimAmount);
        return claimId;
    }
    
    function assessClaim(
        uint256 _claimId,
        ClaimStatus _decision,
        string memory _assessmentReport
    ) external onlyRole(ASSESSOR_ROLE) {
        Claim storage claim = claims[_claimId];
        require(claim.status == ClaimStatus.PENDING, "Claim already assessed");
        require(_decision != ClaimStatus.PENDING, "Invalid decision");
        
        claim.status = _decision;
        claim.assessmentTime = block.timestamp;
        claim.assessor = msg.sender;
        claim.assessmentReport = _assessmentReport;
        
        emit ClaimAssessed(_claimId, _decision, msg.sender);
        
        // 如果批准，自动支付
        if (_decision == ClaimStatus.APPROVED) {
            _payClaim(_claimId);
        }
    }
    
    function _payClaim(uint256 _claimId) internal {
        Claim storage claim = claims[_claimId];
        InsurancePolicy storage policy = policies[claim.policyId];
        
        require(claim.status == ClaimStatus.APPROVED, "Claim not approved");
        
        uint256 payoutAmount = claim.claimAmount - policy.deductible;
        require(riskPools[policy.insuranceType].availableFunds >= payoutAmount, "Insufficient pool funds");
        
        // 更新状态
        claim.status = ClaimStatus.PAID;
        policy.status = PolicyStatus.CLAIMED;
        
        // 更新风险池
        riskPools[policy.insuranceType].availableFunds -= payoutAmount;
        riskPools[policy.insuranceType].totalClaims += payoutAmount;
        riskPools[policy.insuranceType].activePolicies--;
        
        // 支付理赔款
        payable(claim.claimant).transfer(payoutAmount);
        
        emit ClaimPaid(_claimId, claim.claimant, payoutAmount);
    }
    
    function addLiquidity(InsuranceType _poolType) external payable nonReentrant {
        require(msg.value > 0, "Must provide liquidity");
        
        RiskPool storage pool = riskPools[_poolType];
        pool.totalFunds += msg.value;
        pool.availableFunds += msg.value;
        pool.liquidityProviders[msg.sender] += msg.value;
        
        totalTVL += msg.value;
        
        emit LiquidityAdded(msg.sender, _poolType, msg.value);
    }
    
    function removeLiquidity(InsuranceType _poolType, uint256 _amount) external nonReentrant {
        RiskPool storage pool = riskPools[_poolType];
        require(pool.liquidityProviders[msg.sender] >= _amount, "Insufficient liquidity");
        require(pool.availableFunds >= _amount, "Insufficient available funds");
        
        // 先分发奖励
        _distributeRewards(msg.sender, _poolType);
        
        pool.liquidityProviders[msg.sender] -= _amount;
        pool.totalFunds -= _amount;
        pool.availableFunds -= _amount;
        totalTVL -= _amount;
        
        payable(msg.sender).transfer(_amount);
        
        emit LiquidityRemoved(msg.sender, _poolType, _amount);
    }
    
    function _distributeRewards(address _provider, InsuranceType _poolType) internal {
        RiskPool storage pool = riskPools[_poolType];
        uint256 userLiquidity = pool.liquidityProviders[_provider];
        
        if (userLiquidity > 0) {
            uint256 rewards = (userLiquidity * liquidityRewardRate * 1 days) / (365 days * 10000);
            userRewards[_provider] += rewards;
        }
    }
    
    function claimRewards() external nonReentrant {
        uint256 rewards = userRewards[msg.sender];
        require(rewards > 0, "No rewards to claim");
        
        userRewards[msg.sender] = 0;
        payable(msg.sender).transfer(rewards);
        
        emit RewardsDistributed(msg.sender, rewards);
    }
    
    // 查询函数
    function getPolicy(uint256 _policyId) external view returns (InsurancePolicy memory) {
        return policies[_policyId];
    }
    
    function getClaim(uint256 _claimId) external view returns (Claim memory) {
        return claims[_claimId];
    }
    
    function getModelPolicies(string memory _modelId) external view returns (uint256[] memory) {
        return modelPolicies[_modelId];
    }
    
    function getUserPolicies(address _user) external view returns (uint256[] memory) {
        return userPolicies[_user];
    }
    
    function getRiskPoolInfo(InsuranceType _poolType) external view returns (
        uint256 totalFunds,
        uint256 availableFunds,
        uint256 totalClaims,
        uint256 activePolicies,
        uint256 baseRate
    ) {
        RiskPool storage pool = riskPools[_poolType];
        return (
            pool.totalFunds,
            pool.availableFunds,
            pool.totalClaims,
            pool.activePolicies,
            pool.baseRate
        );
    }
    
    function getUserLiquidity(address _user, InsuranceType _poolType) external view returns (uint256) {
        return riskPools[_poolType].liquidityProviders[_user];
    }
}
