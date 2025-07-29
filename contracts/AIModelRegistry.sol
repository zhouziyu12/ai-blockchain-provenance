// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract AIModelRegistry is AccessControl {
    
    bytes32 public constant MODEL_CREATOR_ROLE = keccak256("MODEL_CREATOR_ROLE");
    
    enum ModelStatus { REGISTERED, TRAINING, VALIDATED, DEPLOYED, DEPRECATED }
    enum ModelType { CLASSIFICATION, REGRESSION, CLUSTERING, NLP, COMPUTER_VISION }
    
    struct AIModel {
        string modelId;
        string modelName;
        string version;
        ModelType modelType;
        string algorithm;
        address creator;
        bytes32 integrityHash;
        ModelStatus status;
        uint256 createdAt;
        uint256 updatedAt;
    }
    
    struct ModelMetrics {
        uint256 accuracy;
        uint256 precision; 
        uint256 recall;
        uint256 trainingTime;
    }
    
    mapping(string => AIModel) public models;
    mapping(string => ModelMetrics) public modelMetrics;
    mapping(string => bool) public modelExists;
    mapping(address => string[]) public creatorModels;
    
    event ModelRegistered(string indexed modelId, address indexed creator, uint256 timestamp);
    event MetricsUpdated(string indexed modelId, uint256 accuracy, uint256 timestamp);
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MODEL_CREATOR_ROLE, msg.sender);
    }
    
    function registerModel(
        string memory _modelId,
        string memory _modelName,
        string memory _version,
        ModelType _modelType,
        string memory _algorithm
    ) external onlyRole(MODEL_CREATOR_ROLE) {
        require(!modelExists[_modelId], "Model already exists");
        require(bytes(_modelId).length > 0, "Empty model ID");
        
        bytes32 integrityHash = keccak256(abi.encodePacked(
            _modelName, _version, _algorithm, msg.sender, block.timestamp
        ));
        
        models[_modelId] = AIModel({
            modelId: _modelId,
            modelName: _modelName,
            version: _version,
            modelType: _modelType,
            algorithm: _algorithm,
            creator: msg.sender,
            integrityHash: integrityHash,
            status: ModelStatus.REGISTERED,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });
        
        modelExists[_modelId] = true;
        creatorModels[msg.sender].push(_modelId);
        
        emit ModelRegistered(_modelId, msg.sender, block.timestamp);
    }
    
    function updateModelMetrics(
        string memory _modelId,
        uint256 _accuracy,
        uint256 _precision,
        uint256 _recall,
        uint256 _trainingTime
    ) external {
        require(modelExists[_modelId], "Model does not exist");
        require(models[_modelId].creator == msg.sender, "Only creator allowed");
        
        modelMetrics[_modelId] = ModelMetrics({
            accuracy: _accuracy,
            precision: _precision,
            recall: _recall,
            trainingTime: _trainingTime
        });
        
        models[_modelId].status = ModelStatus.TRAINING;
        models[_modelId].updatedAt = block.timestamp;
        
        emit MetricsUpdated(_modelId, _accuracy, block.timestamp);
    }
    
    function updateModelStatus(string memory _modelId, ModelStatus _status) external {
        require(modelExists[_modelId], "Model does not exist");
        require(models[_modelId].creator == msg.sender, "Only creator allowed");
        
        models[_modelId].status = _status;
        models[_modelId].updatedAt = block.timestamp;
    }
    
    function verifyIntegrity(string memory _modelId) 
        external 
        view 
        returns (bool isValid, bytes32 storedHash, bytes32 calculatedHash) 
    {
        require(modelExists[_modelId], "Model does not exist");
        
        AIModel memory model = models[_modelId];
        calculatedHash = keccak256(abi.encodePacked(
            model.modelName, model.version, model.algorithm, model.creator, model.createdAt
        ));
        
        storedHash = model.integrityHash;
        isValid = (storedHash == calculatedHash);
    }
    
    function getModel(string memory _modelId) external view returns (AIModel memory) {
        require(modelExists[_modelId], "Model does not exist");
        return models[_modelId];
    }
    
    function getModelMetrics(string memory _modelId) external view returns (ModelMetrics memory) {
        require(modelExists[_modelId], "Model does not exist");
        return modelMetrics[_modelId];
    }
    
    function getCreatorModels(address _creator) external view returns (string[] memory) {
        return creatorModels[_creator];
    }
}
