// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract AIModelPredictionMarket is AccessControl, ReentrancyGuard {
    
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    
    enum PredictionType { ACCURACY, DEPLOYMENT_SUCCESS, AUDIT_PASS }
    enum MarketStatus { ACTIVE, RESOLVED, CANCELLED }
    
    struct Market {
        uint256 marketId;
        string modelId;
        PredictionType predictionType;
        string question;
        uint256 targetValue;
        uint256 deadline;
        MarketStatus status;
        uint256 totalYesShares;
        uint256 totalNoShares;
        bool outcome;
        uint256 createdAt;
        address creator;
    }
    
    struct Position {
        uint256 yesShares;
        uint256 noShares;
        uint256 totalInvested;
        bool claimed;
    }
    
    mapping(uint256 => Market) public markets;
    mapping(uint256 => mapping(address => Position)) public positions;
    mapping(uint256 => uint256) public marketPools;
    uint256 public nextMarketId = 1;
    uint256 public constant SHARE_PRICE = 0.01 ether;
    
    event MarketCreated(uint256 indexed marketId, string modelId, string question, uint256 deadline);
    event SharesPurchased(uint256 indexed marketId, address indexed buyer, bool isYes, uint256 shares, uint256 amount);
    event MarketResolved(uint256 indexed marketId, bool outcome, uint256 timestamp);
    event WinningsClaimed(uint256 indexed marketId, address indexed user, uint256 amount);
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ORACLE_ROLE, msg.sender);
    }
    
    function createMarket(
        string memory _modelId,
        PredictionType _predictionType,
        string memory _question,
        uint256 _targetValue,
        uint256 _duration
    ) external returns (uint256) {
        uint256 marketId = nextMarketId++;
        
        markets[marketId] = Market({
            marketId: marketId,
            modelId: _modelId,
            predictionType: _predictionType,
            question: _question,
            targetValue: _targetValue,
            deadline: block.timestamp + _duration,
            status: MarketStatus.ACTIVE,
            totalYesShares: 0,
            totalNoShares: 0,
            outcome: false,
            createdAt: block.timestamp,
            creator: msg.sender
        });
        
        emit MarketCreated(marketId, _modelId, _question, block.timestamp + _duration);
        return marketId;
    }
    
    function buyShares(uint256 _marketId, bool _isYes, uint256 _shares) external payable nonReentrant {
        Market storage market = markets[_marketId];
        require(market.status == MarketStatus.ACTIVE, "Market not active");
        require(block.timestamp < market.deadline, "Market expired");
        require(_shares > 0, "Shares must be greater than 0");
        
        uint256 cost = _shares * SHARE_PRICE;
        require(msg.value >= cost, "Insufficient payment");
        
        Position storage position = positions[_marketId][msg.sender];
        
        if (_isYes) {
            market.totalYesShares += _shares;
            position.yesShares += _shares;
        } else {
            market.totalNoShares += _shares;
            position.noShares += _shares;
        }
        
        position.totalInvested += cost;
        marketPools[_marketId] += cost;
        
        // 退还多余的以太币
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
        
        emit SharesPurchased(_marketId, msg.sender, _isYes, _shares, cost);
    }
    
    function resolveMarket(uint256 _marketId, bool _outcome) external onlyRole(ORACLE_ROLE) {
        Market storage market = markets[_marketId];
        require(market.status == MarketStatus.ACTIVE, "Market not active");
        require(block.timestamp >= market.deadline, "Market not expired");
        
        market.status = MarketStatus.RESOLVED;
        market.outcome = _outcome;
        
        emit MarketResolved(_marketId, _outcome, block.timestamp);
    }
    
    function claimWinnings(uint256 _marketId) external nonReentrant {
        Market storage market = markets[_marketId];
        require(market.status == MarketStatus.RESOLVED, "Market not resolved");
        
        Position storage position = positions[_marketId][msg.sender];
        require(!position.claimed, "Already claimed");
        require(position.totalInvested > 0, "No position in market");
        
        uint256 winningShares = market.outcome ? position.yesShares : position.noShares;
        require(winningShares > 0, "No winning shares");
        
        uint256 totalWinningShares = market.outcome ? market.totalYesShares : market.totalNoShares;
        uint256 payout = (marketPools[_marketId] * winningShares) / totalWinningShares;
        
        position.claimed = true;
        payable(msg.sender).transfer(payout);
        
        emit WinningsClaimed(_marketId, msg.sender, payout);
    }
    
    function getMarket(uint256 _marketId) external view returns (Market memory) {
        return markets[_marketId];
    }
    
    function getPosition(uint256 _marketId, address _user) external view returns (Position memory) {
        return positions[_marketId][_user];
    }
    
    function calculatePotentialWinnings(uint256 _marketId, address _user) external view returns (uint256) {
        Market memory market = markets[_marketId];
        Position memory position = positions[_marketId][_user];
        
        if (market.status != MarketStatus.RESOLVED || position.claimed) {
            return 0;
        }
        
        uint256 winningShares = market.outcome ? position.yesShares : position.noShares;
        if (winningShares == 0) return 0;
        
        uint256 totalWinningShares = market.outcome ? market.totalYesShares : market.totalNoShares;
        return (marketPools[_marketId] * winningShares) / totalWinningShares;
    }
}
