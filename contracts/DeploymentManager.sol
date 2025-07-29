// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract DeploymentManager is AccessControl {
    
    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
    
    struct Deployment {
        uint256 deploymentId;
        string modelId;
        string environment;
        string endpoint;
        bytes32 configHash;
        uint256 timestamp;
        address deployer;
        bool isActive;
        uint256 requestCount;
        uint256 errorCount;
    }
    
    mapping(string => Deployment[]) public modelDeployments;
    mapping(uint256 => Deployment) public deployments;
    uint256 public nextDeploymentId = 1;
    
    event ModelDeployed(string indexed modelId, uint256 deploymentId, string environment, uint256 timestamp);
    event DeploymentUpdated(uint256 indexed deploymentId, uint256 requestCount, uint256 errorCount);
    event DeploymentDeactivated(uint256 indexed deploymentId, uint256 timestamp);
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEPLOYER_ROLE, msg.sender);
    }
    
    function deployModel(
        string memory _modelId,
        string memory _environment,
        string memory _endpoint,
        bytes32 _configHash
    ) external onlyRole(DEPLOYER_ROLE) {
        uint256 deploymentId = nextDeploymentId++;
        
        Deployment memory deployment = Deployment({
            deploymentId: deploymentId,
            modelId: _modelId,
            environment: _environment,
            endpoint: _endpoint,
            configHash: _configHash,
            timestamp: block.timestamp,
            deployer: msg.sender,
            isActive: true,
            requestCount: 0,
            errorCount: 0
        });
        
        modelDeployments[_modelId].push(deployment);
        deployments[deploymentId] = deployment;
        
        emit ModelDeployed(_modelId, deploymentId, _environment, block.timestamp);
    }
    
    function updateDeploymentStats(
        uint256 _deploymentId,
        uint256 _requestCount,
        uint256 _errorCount
    ) external onlyRole(DEPLOYER_ROLE) {
        require(deployments[_deploymentId].deploymentId != 0, "Deployment does not exist");
        
        deployments[_deploymentId].requestCount = _requestCount;
        deployments[_deploymentId].errorCount = _errorCount;
        
        // 同步更新modelDeployments中的数据
        string memory modelId = deployments[_deploymentId].modelId;
        Deployment[] storage modelDeps = modelDeployments[modelId];
        
        for (uint i = 0; i < modelDeps.length; i++) {
            if (modelDeps[i].deploymentId == _deploymentId) {
                modelDeps[i].requestCount = _requestCount;
                modelDeps[i].errorCount = _errorCount;
                break;
            }
        }
        
        emit DeploymentUpdated(_deploymentId, _requestCount, _errorCount);
    }
    
    function deactivateDeployment(uint256 _deploymentId) external onlyRole(DEPLOYER_ROLE) {
        require(deployments[_deploymentId].deploymentId != 0, "Deployment does not exist");
        
        deployments[_deploymentId].isActive = false;
        
        emit DeploymentDeactivated(_deploymentId, block.timestamp);
    }
    
    function getModelDeployments(string memory _modelId) external view returns (Deployment[] memory) {
        return modelDeployments[_modelId];
    }
    
    function getDeployment(uint256 _deploymentId) external view returns (Deployment memory) {
        require(deployments[_deploymentId].deploymentId != 0, "Deployment does not exist");
        return deployments[_deploymentId];
    }
}
