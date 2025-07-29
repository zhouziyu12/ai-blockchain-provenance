// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract AIModelMarketplace is AccessControl, ReentrancyGuard {
    
    bytes32 public constant MARKETPLACE_ADMIN_ROLE = keccak256("MARKETPLACE_ADMIN_ROLE");
    
    enum ListingStatus { ACTIVE, SOLD, CANCELLED, EXPIRED }
    enum AccessType { TEMPORARY, PERMANENT, SUBSCRIPTION }
    
    struct ModelListing {
        uint256 listingId;
        string modelId;
        address owner;
        uint256 price; // 每次使用的价格
        uint256 subscriptionPrice; // 订阅价格（每月）
        AccessType accessType;
        uint256 maxUsages; // 最大使用次数（临时访问）
        uint256 duration; // 访问持续时间（秒）
        ListingStatus status;
        uint256 createdAt;
        uint256 totalSales;
        string description;
        string[] tags;
    }
    
    struct ModelAccess {
        address user;
        string modelId;
        AccessType accessType;
        uint256 usagesRemaining;
        uint256 expiryTime;
        uint256 purchaseTime;
        bool isActive;
    }
    
    struct Usage {
        address user;
        string modelId;
        uint256 timestamp;
        bytes32 inputHash;
        bytes32 outputHash;
        uint256 gasUsed;
    }
    
    mapping(uint256 => ModelListing) public listings;
    mapping(string => uint256) public modelToListing;
    mapping(address => mapping(string => ModelAccess)) public userAccess;
    mapping(string => Usage[]) public modelUsageHistory;
    mapping(address => uint256[]) public userListings;
    mapping(address => uint256) public earnings;
    
    uint256 public nextListingId = 1;
    uint256 public platformFeePercent = 5; // 5% 平台费用
    uint256 public totalVolume;
    
    event ModelListed(uint256 indexed listingId, string modelId, address indexed owner, uint256 price);
    event ModelPurchased(uint256 indexed listingId, address indexed buyer, AccessType accessType, uint256 amount);
    event ModelUsed(string indexed modelId, address indexed user, uint256 timestamp);
    event AccessExpired(string indexed modelId, address indexed user, uint256 timestamp);
    event EarningsWithdrawn(address indexed user, uint256 amount);
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MARKETPLACE_ADMIN_ROLE, msg.sender);
    }
    
    function listModel(
        string memory _modelId,
        uint256 _price,
        uint256 _subscriptionPrice,
        AccessType _accessType,
        uint256 _maxUsages,
        uint256 _duration,
        string memory _description,
        string[] memory _tags
    ) external returns (uint256) {
        require(bytes(_modelId).length > 0, "Invalid model ID");
        require(_price > 0 || _subscriptionPrice > 0, "Price must be greater than 0");
        require(modelToListing[_modelId] == 0, "Model already listed");
        
        uint256 listingId = nextListingId++;
        
        listings[listingId] = ModelListing({
            listingId: listingId,
            modelId: _modelId,
            owner: msg.sender,
            price: _price,
            subscriptionPrice: _subscriptionPrice,
            accessType: _accessType,
            maxUsages: _maxUsages,
            duration: _duration,
            status: ListingStatus.ACTIVE,
            createdAt: block.timestamp,
            totalSales: 0,
            description: _description,
            tags: _tags
        });
        
        modelToListing[_modelId] = listingId;
        userListings[msg.sender].push(listingId);
        
        emit ModelListed(listingId, _modelId, msg.sender, _price);
        return listingId;
    }
    
    function purchaseAccess(
        uint256 _listingId,
        AccessType _requestedAccessType
    ) external payable nonReentrant {
        ModelListing storage listing = listings[_listingId];
        require(listing.status == ListingStatus.ACTIVE, "Listing not active");
        require(listing.owner != msg.sender, "Cannot buy your own model");
        
        uint256 price;
        uint256 duration;
        uint256 usages;
        
        if (_requestedAccessType == AccessType.TEMPORARY) {
            require(listing.accessType == AccessType.TEMPORARY, "Temporary access not available");
            price = listing.price;
            duration = listing.duration;
            usages = listing.maxUsages;
        } else if (_requestedAccessType == AccessType.SUBSCRIPTION) {
            price = listing.subscriptionPrice;
            duration = 30 days; // 一个月订阅
            usages = type(uint256).max; // 无限使用
        } else if (_requestedAccessType == AccessType.PERMANENT) {
            price = listing.price * 12; // 永久访问 = 12个月订阅
            duration = type(uint256).max;
            usages = type(uint256).max;
        }
        
        require(msg.value >= price, "Insufficient payment");
        
        // 计算平台费用
        uint256 platformFee = (price * platformFeePercent) / 100;
        uint256 ownerEarning = price - platformFee;
        
        // 更新收益
        earnings[listing.owner] += ownerEarning;
        earnings[address(this)] += platformFee;
        totalVolume += price;
        
        // 设置用户访问权限
        userAccess[msg.sender][listing.modelId] = ModelAccess({
            user: msg.sender,
            modelId: listing.modelId,
            accessType: _requestedAccessType,
            usagesRemaining: usages,
            expiryTime: duration == type(uint256).max ? type(uint256).max : block.timestamp + duration,
            purchaseTime: block.timestamp,
            isActive: true
        });
        
        listing.totalSales++;
        
        // 退还多余的以太币
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
        
        emit ModelPurchased(_listingId, msg.sender, _requestedAccessType, price);
    }
    
    function useModel(
        string memory _modelId,
        bytes32 _inputHash,
        bytes32 _outputHash
    ) external {
        ModelAccess storage access = userAccess[msg.sender][_modelId];
        require(access.isActive, "No active access to this model");
        require(access.expiryTime > block.timestamp, "Access expired");
        require(access.usagesRemaining > 0, "No usages remaining");
        
        // 记录使用情况
        modelUsageHistory[_modelId].push(Usage({
            user: msg.sender,
            modelId: _modelId,
            timestamp: block.timestamp,
            inputHash: _inputHash,
            outputHash: _outputHash,
            gasUsed: gasleft()
        }));
        
        // 减少剩余使用次数
        if (access.usagesRemaining != type(uint256).max) {
            access.usagesRemaining--;
        }
        
        // 检查是否需要停用访问
        if (access.usagesRemaining == 0 || access.expiryTime <= block.timestamp) {
            access.isActive = false;
            emit AccessExpired(_modelId, msg.sender, block.timestamp);
        }
        
        emit ModelUsed(_modelId, msg.sender, block.timestamp);
    }
    
    function withdrawEarnings() external nonReentrant {
        uint256 amount = earnings[msg.sender];
        require(amount > 0, "No earnings to withdraw");
        
        earnings[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        
        emit EarningsWithdrawn(msg.sender, amount);
    }
    
    function extendAccess(string memory _modelId, uint256 _additionalDays) external payable {
        ModelAccess storage access = userAccess[msg.sender][_modelId];
        require(access.user != address(0), "No existing access");
        
        uint256 listingId = modelToListing[_modelId];
        ModelListing storage listing = listings[listingId];
        
        uint256 dailyRate = listing.subscriptionPrice / 30;
        uint256 extensionCost = dailyRate * _additionalDays;
        require(msg.value >= extensionCost, "Insufficient payment");
        
        access.expiryTime += _additionalDays * 1 days;
        access.isActive = true;
        
        earnings[listing.owner] += extensionCost;
    }
    
    function getModelUsageStats(string memory _modelId) external view returns (
        uint256 totalUsages,
        uint256 uniqueUsers,
        uint256 recentUsages
    ) {
        Usage[] memory usages = modelUsageHistory[_modelId];
        totalUsages = usages.length;
        
        // 计算最近7天的使用情况
        uint256 weekAgo = block.timestamp - 7 days;
        recentUsages = 0;
        
        address[] memory users = new address[](usages.length);
        uint256 userCount = 0;
        
        for (uint i = 0; i < usages.length; i++) {
            if (usages[i].timestamp >= weekAgo) {
                recentUsages++;
            }
            
            // 检查是否是新用户
            bool isNewUser = true;
            for (uint j = 0; j < userCount; j++) {
                if (users[j] == usages[i].user) {
                    isNewUser = false;
                    break;
                }
            }
            if (isNewUser) {
                users[userCount] = usages[i].user;
                userCount++;
            }
        }
        
        uniqueUsers = userCount;
    }
    
    function hasAccess(address _user, string memory _modelId) external view returns (bool) {
        ModelAccess memory access = userAccess[_user][_modelId];
        return access.isActive && 
               access.expiryTime > block.timestamp && 
               access.usagesRemaining > 0;
    }
    
    function getListing(uint256 _listingId) external view returns (ModelListing memory) {
        return listings[_listingId];
    }
    
    function getUserAccess(address _user, string memory _modelId) external view returns (ModelAccess memory) {
        return userAccess[_user][_modelId];
    }
    
    function getUserListings(address _user) external view returns (uint256[] memory) {
        return userListings[_user];
    }
    
    function setPlatformFee(uint256 _feePercent) external onlyRole(MARKETPLACE_ADMIN_ROLE) {
        require(_feePercent <= 20, "Fee too high"); // 最大20%
        platformFeePercent = _feePercent;
    }
}
