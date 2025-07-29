// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract AIModelTokenV2 is ERC20, AccessControl, ReentrancyGuard {
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant REWARD_MANAGER_ROLE = keccak256("REWARD_MANAGER_ROLE");
    bytes32 public constant INSURANCE_ROLE = keccak256("INSURANCE_ROLE");
    
    enum StakingType { 
        MODEL_DEVELOPMENT,    // 模型开发质押
        INSURANCE_LIQUIDITY,  // 保险流动性质押  
        GOVERNANCE,          // 治理质押
        VALIDATOR            // 验证者质押
    }
    
    struct StakingPool {
        StakingType poolType;
        uint256 totalStaked;
        uint256 rewardRate;        // 每秒奖励率
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        uint256 minimumStake;
        uint256 lockPeriod;
        bool isActive;
    }
    
    struct UserStake {
        uint256 amount;
        uint256 rewardPerTokenPaid;
        uint256 rewards;
        uint256 stakeTime;
        uint256 unlockTime;
        bool isLocked;
    }
    
    // 核心映射
    mapping(uint256 => StakingPool) public stakingPools;
    mapping(uint256 => mapping(address => UserStake)) public userStakes;
    mapping(address => uint256[]) public userPoolIds;
    
    // 模型相关
    mapping(string => uint256) public modelRewardPool;
    mapping(address => mapping(string => uint256)) public userModelStakes;
    mapping(string => address[]) public modelStakers;
    
    // 保险相关
    mapping(address => uint256) public insuranceLiquidity;
    mapping(uint256 => uint256) public insurancePoolRewards;
    mapping(address => uint256) public insuranceRewards;
    
    // 治理相关
    mapping(address => uint256) public governanceWeight;
    mapping(address => uint256) public votingPower;
    
    // 全局状态
    uint256 public constant TOTAL_SUPPLY = 1000000000 * 10**18; // 10亿代币
    uint256 public nextPoolId = 1;
    uint256 public totalInsuranceFunds;
    uint256 public protocolRevenue;
    uint256 public totalRewardsDistributed;
    
    // 事件
    event PoolCreated(uint256 indexed poolId, StakingType poolType, uint256 rewardRate);
    event TokensStaked(address indexed user, uint256 indexed poolId, uint256 amount, string extraData);
    event TokensUnstaked(address indexed user, uint256 indexed poolId, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 indexed poolId, uint256 amount);
    event ModelRewardDistributed(string indexed modelId, uint256 amount);
    event InsuranceClaimPaid(address indexed claimant, uint256 amount);
    event GovernanceWeightUpdated(address indexed user, uint256 oldWeight, uint256 newWeight);
    
    constructor() ERC20("AI Model Ecosystem Token", "AIMT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(REWARD_MANAGER_ROLE, msg.sender);
        _grantRole(INSURANCE_ROLE, msg.sender);
        
        // 初始代币分配
        _mint(msg.sender, TOTAL_SUPPLY * 15 / 100);      // 15% 团队
        _mint(address(this), TOTAL_SUPPLY * 60 / 100);   // 60% 生态奖励池
        // 25% 预留给社区空投、流动性激励等
        
        // 创建默认质押池
        _createDefaultPools();
    }
    
    function _createDefaultPools() internal {
        // 模型开发池：高奖励，长锁定
        _createPool(StakingType.MODEL_DEVELOPMENT, 1e16, 1000 * 1e18, 90 days); 
        
        // 保险流动性池：中等奖励，中等锁定
        _createPool(StakingType.INSURANCE_LIQUIDITY, 5e15, 500 * 1e18, 30 days); 
        
        // 治理池：低奖励，短锁定
        _createPool(StakingType.GOVERNANCE, 2e15, 100 * 1e18, 7 days); 
        
        // 验证者池：中等奖励，中等锁定
        _createPool(StakingType.VALIDATOR, 8e15, 10000 * 1e18, 60 days); 
    }
    
    function _createPool(
        StakingType _poolType,
        uint256 _rewardRate,
        uint256 _minimumStake,
        uint256 _lockPeriod
    ) internal returns (uint256) {
        uint256 poolId = nextPoolId++;
        
        stakingPools[poolId] = StakingPool({
            poolType: _poolType,
            totalStaked: 0,
            rewardRate: _rewardRate,
            lastUpdateTime: block.timestamp,
            rewardPerTokenStored: 0,
            minimumStake: _minimumStake,
            lockPeriod: _lockPeriod,
            isActive: true
        });
        
        emit PoolCreated(poolId, _poolType, _rewardRate);
        return poolId;
    }
    
    function createCustomPool(
        StakingType _poolType,
        uint256 _rewardRate,
        uint256 _minimumStake,
        uint256 _lockPeriod
    ) external onlyRole(REWARD_MANAGER_ROLE) returns (uint256) {
        return _createPool(_poolType, _rewardRate, _minimumStake, _lockPeriod);
    }
    
    modifier updateReward(address _account, uint256 _poolId) {
        StakingPool storage pool = stakingPools[_poolId];
        pool.rewardPerTokenStored = rewardPerToken(_poolId);
        pool.lastUpdateTime = block.timestamp;
        
        if (_account != address(0)) {
            UserStake storage userStake = userStakes[_poolId][_account];
            userStake.rewards = earned(_account, _poolId);
            userStake.rewardPerTokenPaid = pool.rewardPerTokenStored;
        }
        _;
    }
    
    function rewardPerToken(uint256 _poolId) public view returns (uint256) {
        StakingPool storage pool = stakingPools[_poolId];
        if (pool.totalStaked == 0) {
            return pool.rewardPerTokenStored;
        }
        
        return pool.rewardPerTokenStored + 
               (((block.timestamp - pool.lastUpdateTime) * pool.rewardRate * 1e18) / pool.totalStaked);
    }
    
    function earned(address _account, uint256 _poolId) public view returns (uint256) {
        UserStake storage userStake = userStakes[_poolId][_account];
        
        return (userStake.amount * 
                (rewardPerToken(_poolId) - userStake.rewardPerTokenPaid)) / 1e18 + 
                userStake.rewards;
    }
    
    function stakeTokens(
        uint256 _poolId,
        uint256 _amount,
        string memory _extraData
    ) external nonReentrant updateReward(msg.sender, _poolId) {
        StakingPool storage pool = stakingPools[_poolId];
        require(pool.isActive, "Pool not active");
        require(_amount >= pool.minimumStake, "Below minimum stake");
        require(balanceOf(msg.sender) >= _amount, "Insufficient balance");
        
        UserStake storage userStake = userStakes[_poolId][msg.sender];
        
        // 如果是首次质押到这个池子，记录池子ID
        if (userStake.amount == 0) {
            userPoolIds[msg.sender].push(_poolId);
        }
        
        _transfer(msg.sender, address(this), _amount);
        
        pool.totalStaked += _amount;
        userStake.amount += _amount;
        userStake.stakeTime = block.timestamp;
        userStake.unlockTime = block.timestamp + pool.lockPeriod;
        userStake.isLocked = true;
        
        // 根据质押类型执行特殊逻辑
        _handleStakeByType(pool.poolType, msg.sender, _amount, _extraData);
        
        emit TokensStaked(msg.sender, _poolId, _amount, _extraData);
    }
    
    function _handleStakeByType(
        StakingType _poolType,
        address _user,
        uint256 _amount,
        string memory _extraData
    ) internal {
        if (_poolType == StakingType.MODEL_DEVELOPMENT) {
            // 模型开发质押
            userModelStakes[_user][_extraData] += _amount;
            modelStakers[_extraData].push(_user);
            
        } else if (_poolType == StakingType.INSURANCE_LIQUIDITY) {
            // 保险流动性质押
            insuranceLiquidity[_user] += _amount;
            totalInsuranceFunds += _amount;
            
        } else if (_poolType == StakingType.GOVERNANCE) {
            // 治理质押：计算投票权重
            uint256 oldWeight = governanceWeight[_user];
            uint256 newWeight = oldWeight + calculateGovernanceWeight(_amount);
            governanceWeight[_user] = newWeight;
            votingPower[_user] = newWeight;
            
            emit GovernanceWeightUpdated(_user, oldWeight, newWeight);
            
        } else if (_poolType == StakingType.VALIDATOR) {
            // 验证者质押：需要较高门槛
            require(_amount >= 10000 * 1e18, "Validator requires minimum 10k AIMT");
        }
    }
    
    function calculateGovernanceWeight(uint256 _amount) public pure returns (uint256) {
        // 使用平方根函数防止巨鲸控制，同时给予足够激励
        return sqrt(_amount / 1e18) * 1e18;
    }
    
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
    
    function unstakeTokens(uint256 _poolId, uint256 _amount) 
        external 
        nonReentrant 
        updateReward(msg.sender, _poolId) 
    {
        StakingPool storage pool = stakingPools[_poolId];
        UserStake storage userStake = userStakes[_poolId][msg.sender];
        
        require(userStake.amount >= _amount, "Insufficient staked amount");
        require(block.timestamp >= userStake.unlockTime, "Tokens still locked");
        
        pool.totalStaked -= _amount;
        userStake.amount -= _amount;
        
        // 处理特殊类型的解质押
        _handleUnstakeByType(pool.poolType, msg.sender, _amount);
        
        if (userStake.amount == 0) {
            userStake.isLocked = false;
        }
        
        _transfer(address(this), msg.sender, _amount);
        
        emit TokensUnstaked(msg.sender, _poolId, _amount);
    }
    
    function _handleUnstakeByType(
        StakingType _poolType,
        address _user,
        uint256 _amount
    ) internal {
        if (_poolType == StakingType.INSURANCE_LIQUIDITY) {
            insuranceLiquidity[_user] -= _amount;
            totalInsuranceFunds -= _amount;
            
        } else if (_poolType == StakingType.GOVERNANCE) {
            uint256 oldWeight = governanceWeight[_user];
            uint256 reductionWeight = calculateGovernanceWeight(_amount);
            uint256 newWeight = oldWeight > reductionWeight ? oldWeight - reductionWeight : 0;
            
            governanceWeight[_user] = newWeight;
            votingPower[_user] = newWeight;
            
            emit GovernanceWeightUpdated(_user, oldWeight, newWeight);
        }
    }
    
    function claimRewards(uint256 _poolId) 
        external 
        nonReentrant 
        updateReward(msg.sender, _poolId) 
    {
        UserStake storage userStake = userStakes[_poolId][msg.sender];
        uint256 reward = userStake.rewards;
        
        if (reward > 0) {
            userStake.rewards = 0;
            totalRewardsDistributed += reward;
            
            _transfer(address(this), msg.sender, reward);
            
            emit RewardsClaimed(msg.sender, _poolId, reward);
        }
    }
    
    function claimAllRewards() external nonReentrant {
        uint256[] memory poolIds = userPoolIds[msg.sender];
        uint256 totalReward = 0;
        
        for (uint i = 0; i < poolIds.length; i++) {
            uint256 poolId = poolIds[i];
            UserStake storage userStake = userStakes[poolId][msg.sender];
            
            // 更新奖励
            stakingPools[poolId].rewardPerTokenStored = rewardPerToken(poolId);
            stakingPools[poolId].lastUpdateTime = block.timestamp;
            
            uint256 currentReward = earned(msg.sender, poolId);
            userStake.rewards = currentReward;
            userStake.rewardPerTokenPaid = stakingPools[poolId].rewardPerTokenStored;
            
            if (currentReward > 0) {
                totalReward += currentReward;
                userStake.rewards = 0;
                
                emit RewardsClaimed(msg.sender, poolId, currentReward);
            }
        }
        
        if (totalReward > 0) {
            totalRewardsDistributed += totalReward;
            _transfer(address(this), msg.sender, totalReward);
        }
    }
    
    // 保险相关功能
    function payInsuranceClaim(address _claimant, uint256 _amount) 
        external 
        onlyRole(INSURANCE_ROLE) 
    {
        require(totalInsuranceFunds >= _amount, "Insufficient insurance funds");
        
        totalInsuranceFunds -= _amount;
        _transfer(address(this), _claimant, _amount);
        
        // 向流动性提供者分发风险补偿
        uint256 rewardAmount = _amount * 3 / 100; // 3% 风险补偿
        insurancePoolRewards[2] += rewardAmount; // 假设poolId=2是保险池
        
        emit InsuranceClaimPaid(_claimant, _amount);
    }
    
    // 模型奖励分发
    function distributeModelRewards(string memory _modelId, uint256 _amount) 
        external 
        onlyRole(REWARD_MANAGER_ROLE) 
    {
        require(_amount <= balanceOf(address(this)), "Insufficient contract balance");
        
        modelRewardPool[_modelId] += _amount;
        
        // 向模型质押者分发奖励
        address[] memory stakers = modelStakers[_modelId];
        uint256 totalModelStake = 0;
        
        // 计算总质押量
        for (uint i = 0; i < stakers.length; i++) {
            totalModelStake += userModelStakes[stakers[i]][_modelId];
        }
        
        // 按比例分发奖励
        if (totalModelStake > 0) {
            for (uint i = 0; i < stakers.length; i++) {
                address staker = stakers[i];
                uint256 stakerShare = (userModelStakes[staker][_modelId] * _amount) / totalModelStake;
                
                if (stakerShare > 0) {
                    _transfer(address(this), staker, stakerShare);
                }
            }
        }
        
        emit ModelRewardDistributed(_modelId, _amount);
    }
    
    // 查询函数
    function getUserStakeInfo(address _user, uint256 _poolId) 
        external 
        view 
        returns (UserStake memory) 
    {
        return userStakes[_poolId][_user];
    }
    
    function getPoolInfo(uint256 _poolId) 
        external 
        view 
        returns (StakingPool memory) 
    {
        return stakingPools[_poolId];
    }
    
    function getUserPools(address _user) external view returns (uint256[] memory) {
        return userPoolIds[_user];
    }
    
    function getInsuranceStats(address _user) 
        external 
        view 
        returns (
            uint256 userLiquidity,
            uint256 totalFunds,
            uint256 pendingRewards
        ) 
    {
        return (
            insuranceLiquidity[_user],
            totalInsuranceFunds,
            insuranceRewards[_user]
        );
    }
    
    function getGovernanceInfo(address _user) 
        external 
        view 
        returns (
            uint256 weight,
            uint256 userVotingPower
        ) 
    {
        return (
            governanceWeight[_user],
            votingPower[_user]
        );
    }
    
    function getEcosystemStats() 
        external 
        view 
        returns (
            uint256 totalSupply_,
            uint256 circulatingSupply,
            uint256 totalStaked,
            uint256 totalRewardsDistributed_,
            uint256 protocolRevenue_
        ) 
    {
        uint256 totalStakedAmount = 0;
        for (uint i = 1; i < nextPoolId; i++) {
            totalStakedAmount += stakingPools[i].totalStaked;
        }
        
        return (
            TOTAL_SUPPLY,
            TOTAL_SUPPLY - balanceOf(address(this)),
            totalStakedAmount,
            totalRewardsDistributed,
            protocolRevenue
        );
    }
    
    // 紧急功能
    function emergencyWithdraw(uint256 _poolId) external nonReentrant {
        UserStake storage userStake = userStakes[_poolId][msg.sender];
        require(userStake.amount > 0, "No tokens staked");
        
        uint256 amount = userStake.amount;
        stakingPools[_poolId].totalStaked -= amount;
        userStake.amount = 0;
        userStake.rewards = 0; // 放弃奖励
        
        _transfer(address(this), msg.sender, amount);
        
        emit TokensUnstaked(msg.sender, _poolId, amount);
    }
}
