// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract TrainingDataManager is AccessControl {
    
    bytes32 public constant DATA_MANAGER_ROLE = keccak256("DATA_MANAGER_ROLE");
    
    enum DataType { TRAINING, VALIDATION, TEST, INFERENCE }
    
    struct TrainingData {
        bytes32 datasetHash;
        string datasetName;
        DataType dataType;
        uint256 dataSize;
        string dataSource;
        string preprocessing;
        bytes32 labelHash;
        uint256 timestamp;
        address uploader;
        bool isVerified;
    }
    
    mapping(string => TrainingData[]) public modelTrainingData;
    mapping(bytes32 => bool) public datasetExists;
    mapping(string => mapping(bytes32 => bool)) public modelDatasets;
    
    event TrainingDataAdded(string indexed modelId, bytes32 datasetHash, DataType dataType, uint256 timestamp);
    event DatasetVerified(bytes32 indexed datasetHash, address verifier, uint256 timestamp);
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DATA_MANAGER_ROLE, msg.sender);
    }
    
    function addTrainingData(
        string memory _modelId,
        bytes32 _datasetHash,
        string memory _datasetName,
        DataType _dataType,
        uint256 _dataSize,
        string memory _dataSource,
        string memory _preprocessing,
        bytes32 _labelHash
    ) external onlyRole(DATA_MANAGER_ROLE) {
        require(!modelDatasets[_modelId][_datasetHash], "Dataset already added to model");
        
        modelTrainingData[_modelId].push(TrainingData({
            datasetHash: _datasetHash,
            datasetName: _datasetName,
            dataType: _dataType,
            dataSize: _dataSize,
            dataSource: _dataSource,
            preprocessing: _preprocessing,
            labelHash: _labelHash,
            timestamp: block.timestamp,
            uploader: msg.sender,
            isVerified: false
        }));
        
        datasetExists[_datasetHash] = true;
        modelDatasets[_modelId][_datasetHash] = true;
        
        emit TrainingDataAdded(_modelId, _datasetHash, _dataType, block.timestamp);
    }
    
    function verifyDataset(bytes32 _datasetHash) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(datasetExists[_datasetHash], "Dataset does not exist");
        
        // 这里需要遍历所有模型的数据来找到对应的数据集并标记为验证
        // 简化实现，实际中可能需要更复杂的索引
        
        emit DatasetVerified(_datasetHash, msg.sender, block.timestamp);
    }
    
    function getModelTrainingData(string memory _modelId) external view returns (TrainingData[] memory) {
        return modelTrainingData[_modelId];
    }
    
    function getDatasetCount(string memory _modelId) external view returns (uint256) {
        return modelTrainingData[_modelId].length;
    }
}
