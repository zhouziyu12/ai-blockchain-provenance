// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract FederatedLearningCoordinator is AccessControl {
    
    bytes32 public constant COORDINATOR_ROLE = keccak256("COORDINATOR_ROLE");
    bytes32 public constant PARTICIPANT_ROLE = keccak256("PARTICIPANT_ROLE");
    
    enum TrainingStatus { CREATED, ACTIVE, COMPLETED, FAILED }
    
    struct FederatedTraining {
        uint256 trainingId;
        string modelId;
        address coordinator;
        uint256 minParticipants;
        uint256 maxParticipants;
        uint256 rounds;
        uint256 currentRound;
        TrainingStatus status;
        uint256 startTime;
        uint256 deadline;
        bytes32 globalModelHash;
        uint256 participantCount;
        uint256 rewardPerParticipant;
    }
    
    struct Participant {
        address participantAddress;
        bytes32 localModelHash;
        uint256 dataSize;
        bool submitted;
        uint256 contribution;
        uint256 rewardEarned;
    }
    
    mapping(uint256 => FederatedTraining) public trainingSessions;
    mapping(uint256 => mapping(address => Participant)) public participants;
    mapping(uint256 => address[]) public trainingParticipants;
    mapping(uint256 => mapping(uint256 => bytes32)) public roundModels; // trainingId => round => modelHash
    
    uint256 public nextTrainingId = 1;
    
    event TrainingCreated(uint256 indexed trainingId, string modelId, address coordinator, uint256 timestamp);
    event ParticipantJoined(uint256 indexed trainingId, address participant, uint256 dataSize);
    event RoundCompleted(uint256 indexed trainingId, uint256 round, bytes32 globalModelHash);
    event TrainingCompleted(uint256 indexed trainingId, bytes32 finalModelHash, uint256 timestamp);
    event RewardsDistributed(uint256 indexed trainingId, address participant, uint256 amount);
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(COORDINATOR_ROLE, msg.sender);
    }
    
    function createTraining(
        string memory _modelId,
        uint256 _minParticipants,
        uint256 _maxParticipants,
        uint256 _rounds,
        uint256 _duration,
        uint256 _rewardPerParticipant
    ) external onlyRole(COORDINATOR_ROLE) payable returns (uint256) {
        require(_minParticipants > 0, "Min participants must be > 0");
        require(_maxParticipants >= _minParticipants, "Invalid participant limits");
        require(_rounds > 0, "Rounds must be > 0");
        
        uint256 totalReward = _rewardPerParticipant * _maxParticipants;
        require(msg.value >= totalReward, "Insufficient reward funding");
        
        uint256 trainingId = nextTrainingId++;
        
        trainingSessions[trainingId] = FederatedTraining({
            trainingId: trainingId,
            modelId: _modelId,
            coordinator: msg.sender,
            minParticipants: _minParticipants,
            maxParticipants: _maxParticipants,
            rounds: _rounds,
            currentRound: 0,
            status: TrainingStatus.CREATED,
            startTime: 0,
            deadline: block.timestamp + _duration,
            globalModelHash: bytes32(0),
            participantCount: 0,
            rewardPerParticipant: _rewardPerParticipant
        });
        
        emit TrainingCreated(trainingId, _modelId, msg.sender, block.timestamp);
        return trainingId;
    }
    
    function joinTraining(
        uint256 _trainingId,
        uint256 _dataSize
    ) external {
        FederatedTraining storage training = trainingSessions[_trainingId];
        require(training.status == TrainingStatus.CREATED, "Training not available");
        require(training.participantCount < training.maxParticipants, "Training full");
        require(participants[_trainingId][msg.sender].participantAddress == address(0), "Already joined");
        require(_dataSize > 0, "Data size must be > 0");
        
        participants[_trainingId][msg.sender] = Participant({
            participantAddress: msg.sender,
            localModelHash: bytes32(0),
            dataSize: _dataSize,
            submitted: false,
            contribution: 0,
            rewardEarned: 0
        });
        
        trainingParticipants[_trainingId].push(msg.sender);
        training.participantCount++;
        
        // 如果达到最小参与者数量，开始训练
        if (training.participantCount >= training.minParticipants && training.status == TrainingStatus.CREATED) {
            training.status = TrainingStatus.ACTIVE;
            training.startTime = block.timestamp;
        }
        
        emit ParticipantJoined(_trainingId, msg.sender, _dataSize);
    }
    
    function submitLocalModel(
        uint256 _trainingId,
        bytes32 _localModelHash
    ) external {
        FederatedTraining storage training = trainingSessions[_trainingId];
        require(training.status == TrainingStatus.ACTIVE, "Training not active");
        require(participants[_trainingId][msg.sender].participantAddress != address(0), "Not a participant");
        require(!participants[_trainingId][msg.sender].submitted, "Already submitted for this round");
        
        participants[_trainingId][msg.sender].localModelHash = _localModelHash;
        participants[_trainingId][msg.sender].submitted = true;
        
        // 计算贡献度（基于数据大小）
        uint256 totalDataSize = 0;
        uint256 submittedCount = 0;
        
        for (uint i = 0; i < trainingParticipants[_trainingId].length; i++) {
            address participant = trainingParticipants[_trainingId][i];
            if (participants[_trainingId][participant].submitted) {
                totalDataSize += participants[_trainingId][participant].dataSize;
                submittedCount++;
            }
        }
        
        // 如果所有参与者都提交了，完成这一轮
        if (submittedCount == training.participantCount) {
            completeRound(_trainingId, totalDataSize);
        }
    }
    
    function completeRound(uint256 _trainingId, uint256 _totalDataSize) internal {
        FederatedTraining storage training = trainingSessions[_trainingId];
        training.currentRound++;
        
        // 计算每个参与者的贡献度
        for (uint i = 0; i < trainingParticipants[_trainingId].length; i++) {
            address participant = trainingParticipants[_trainingId][i];
            if (participants[_trainingId][participant].submitted) {
                uint256 contribution = (participants[_trainingId][participant].dataSize * 100) / _totalDataSize;
                participants[_trainingId][participant].contribution += contribution;
                participants[_trainingId][participant].submitted = false; // 重置下一轮
            }
        }
        
        // 生成全局模型哈希（简化版本）
        bytes32 globalHash = keccak256(abi.encodePacked(_trainingId, training.currentRound, block.timestamp));
        training.globalModelHash = globalHash;
        roundModels[_trainingId][training.currentRound] = globalHash;
        
        emit RoundCompleted(_trainingId, training.currentRound, globalHash);
        
        // 检查是否完成所有轮次
        if (training.currentRound >= training.rounds) {
            training.status = TrainingStatus.COMPLETED;
            distributeRewards(_trainingId);
            emit TrainingCompleted(_trainingId, globalHash, block.timestamp);
        }
    }
    
    function distributeRewards(uint256 _trainingId) internal {
        FederatedTraining storage training = trainingSessions[_trainingId];
        
        for (uint i = 0; i < trainingParticipants[_trainingId].length; i++) {
            address participant = trainingParticipants[_trainingId][i];
            uint256 reward = (training.rewardPerParticipant * participants[_trainingId][participant].contribution) / 100;
            
            participants[_trainingId][participant].rewardEarned = reward;
            payable(participant).transfer(reward);
            
            emit RewardsDistributed(_trainingId, participant, reward);
        }
    }
    
    function getTraining(uint256 _trainingId) external view returns (FederatedTraining memory) {
        return trainingSessions[_trainingId];
    }
    
    function getParticipant(uint256 _trainingId, address _participant) external view returns (Participant memory) {
        return participants[_trainingId][_participant];
    }
    
    function getTrainingParticipants(uint256 _trainingId) external view returns (address[] memory) {
        return trainingParticipants[_trainingId];
    }
}
