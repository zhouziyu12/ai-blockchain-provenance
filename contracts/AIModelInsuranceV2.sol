// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./AIModelTokenV2.sol";

contract AIModelInsuranceV2 is AccessControl, ReentrancyGuard {
    
    bytes32 public constant INSURER_ROLE = keccak256("INSURER_ROLE");
    bytes32 public constant ASSESSOR_ROLE = keccak256("ASSESSOR_ROLE");
    
    enum InsuranceType { 
        PERFORMANCE_GUARANTEE,  
        DATA_BREACH,           
        DEPLOYMENT_FAILURE,    
        REVENUE_PROTECTION,    
        COMPLIANCE_RISK       
    }
    
    enum PolicyStatus { ACTIVE, CLAIMED, EXPIRED, CANCELLED }
    enum ClaimStatus { PENDING, APPROVED, REJECTED, PAID }
    
    struct InsurancePolicy {
        uint256 policyId;
        string modelId;
        address policyholder;
        InsuranceType insuranceType;
        uint256 coverageAmount;
        uint256 premium;
        uint256 deductible;
        uint256 startTime;
        uint256 endTime;
        PolicyStatus status;
        bytes32 termsHash;
        uint256 riskScore;
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
        string evidenceHash;
        string assessmentReport;
    }
    
    AIModelTokenV2 public immutable aimtToken;
    
    mapping(uint256 => InsurancePolicy) public policies;
    mapping(uint256 => Claim) public claims;
    mapping(string => uint256[]) public modelPolicies;
    mapping(address => uint256[]) public userPolicies;
    mapping(InsuranceType => uint256) public baseRates;
    
    uint256 public nextPolicyId = 1;
    uint256 public nextClaimId = 1;
    uint256 public protocolFeeRate = 300; // 3%
    
    event PolicyCreated(uint256 indexed policyId, string modelId, address indexed policyholder, uint256 coverageAmount);
    event ClaimSubmitted(uint256 indexed claimId, uint256 indexed policyId, address indexed claimant, uint256 amount);
    event ClaimPaid(uint256 indexed claimId, address indexed claimant, uint256 amount);
    
    constructor(address _aimtToken) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(INSURER_ROLE, msg.sender);
        _grantRole(ASSESSOR_ROLE, msg.sender);
        
        aimtToken = AIModelTokenV2(_aimtToken);
        
        // 设置基础费率
        baseRates[InsuranceType.PERFORMANCE_GUARANTEE] = 500;  // 5%
        baseRates[InsuranceType.DATA_BREACH] = 700;           // 7%
        baseRates[InsuranceType.DEPLOYMENT_FAILURE] = 600;    // 6%
        baseRates[InsuranceType.REVENUE_PROTECTION] = 800;    // 8%
        baseRates[InsuranceType.COMPLIANCE_RISK] = 900;       // 9%
    }
    
    function calculatePremium(
        string memory _modelId,
        InsuranceType _type,
        uint256 _coverageAmount,
        uint256 _duration
    ) public view returns (uint256 premium, uint256 riskScore) {
        riskScore = calculateRiskScore(_modelId, _type);
        
        uint256 baseRate = baseRates[_type];
        uint256 riskAdjustment = (riskScore * 500) / 1000;
        uint256 timeAdjustment = (_duration * 100) / 365 days;
        
        uint256 totalRate = baseRate + riskAdjustment + timeAdjustment;
        premium = (_coverageAmount * totalRate) / 10000;
    }
    
    function calculateRiskScore(string memory _modelId, InsuranceType _type) 
        internal 
        pure 
        returns (uint256) 
    {
        bytes32 modelHash = keccak256(bytes(_modelId));
        uint256 baseScore = uint256(modelHash) % 500;
        
        if (_type == InsuranceType.DATA_BREACH) {
            baseScore += 200;
        } else if (_type == InsuranceType.COMPLIANCE_RISK) {
            baseScore += 300;
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
    ) external returns (uint256) {
        require(_coverageAmount > 0, "Coverage amount must be > 0");
        require(_duration >= 30 days && _duration <= 365 days, "Invalid duration");
        
        (uint256 premium, uint256 riskScore) = calculatePremium(
            _modelId, _insuranceType, _coverageAmount, _duration
        );
        
        // 检查保险池资金是否充足
        (,uint256 totalFunds,) = aimtToken.getInsuranceStats(address(this));
        require(totalFunds >= _coverageAmount, "Insufficient insurance funds");
        
        // 收取保险费 (AIMT代币)
        require(aimtToken.transferFrom(msg.sender, address(this), premium), "Premium payment failed");
        
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
        
        modelPolicies[_modelId].push(policyId);
        userPolicies[msg.sender].push(policyId);
        
        emit PolicyCreated(policyId, _modelId, msg.sender, _coverageAmount);
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
        
        claim.status = _decision;
        claim.assessmentTime = block.timestamp;
        claim.assessor = msg.sender;
        claim.assessmentReport = _assessmentReport;
        
        if (_decision == ClaimStatus.APPROVED) {
            _payClaim(_claimId);
        }
    }
    
    function _payClaim(uint256 _claimId) internal {
        Claim storage claim = claims[_claimId];
        InsurancePolicy storage policy = policies[claim.policyId];
        
        uint256 payoutAmount = claim.claimAmount > policy.deductible ? 
                              claim.claimAmount - policy.deductible : 0;
        
        if (payoutAmount > 0) {
            // 通过代币合约支付理赔
            aimtToken.payInsuranceClaim(claim.claimant, payoutAmount);
            
            claim.status = ClaimStatus.PAID;
            policy.status = PolicyStatus.CLAIMED;
            
            emit ClaimPaid(_claimId, claim.claimant, payoutAmount);
        }
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
}
