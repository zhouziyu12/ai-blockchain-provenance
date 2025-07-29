// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract AuditManager is AccessControl {
    
    bytes32 public constant AUDITOR_ROLE = keccak256("AUDITOR_ROLE");
    
    struct AuditRecord {
        uint256 auditId;
        string modelId;
        address auditor;
        string findings;
        uint256 score;
        bool approved;
        uint256 timestamp;
        string certification;
    }
    
    mapping(string => AuditRecord[]) public modelAudits;
    mapping(uint256 => AuditRecord) public audits;
    mapping(string => uint256) public modelReputation;
    uint256 public nextAuditId = 1;
    
    event ModelAudited(string indexed modelId, uint256 auditId, address indexed auditor, bool approved, uint256 timestamp);
    event ReputationUpdated(string indexed modelId, uint256 newReputation, uint256 timestamp);
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(AUDITOR_ROLE, msg.sender);
    }
    
    function auditModel(
        string memory _modelId,
        string memory _findings,
        uint256 _score,
        bool _approved,
        string memory _certification
    ) external onlyRole(AUDITOR_ROLE) {
        require(_score <= 100, "Score must be <= 100");
        
        uint256 auditId = nextAuditId++;
        
        AuditRecord memory audit = AuditRecord({
            auditId: auditId,
            modelId: _modelId,
            auditor: msg.sender,
            findings: _findings,
            score: _score,
            approved: _approved,
            timestamp: block.timestamp,
            certification: _certification
        });
        
        modelAudits[_modelId].push(audit);
        audits[auditId] = audit;
        
        // 更新信誉分
        uint256 currentReputation = modelReputation[_modelId];
        if (currentReputation == 0) currentReputation = 100; // 初始值
        
        if (_approved && _score >= 80) {
            modelReputation[_modelId] = currentReputation + 20 > 1000 ? 1000 : currentReputation + 20;
        } else if (!_approved || _score < 50) {
            modelReputation[_modelId] = currentReputation > 30 ? currentReputation - 30 : 0;
        }
        
        emit ModelAudited(_modelId, auditId, msg.sender, _approved, block.timestamp);
        emit ReputationUpdated(_modelId, modelReputation[_modelId], block.timestamp);
    }
    
    function getModelAudits(string memory _modelId) external view returns (AuditRecord[] memory) {
        return modelAudits[_modelId];
    }
    
    function getAudit(uint256 _auditId) external view returns (AuditRecord memory) {
        require(audits[_auditId].auditId != 0, "Audit does not exist");
        return audits[_auditId];
    }
    
    function getModelReputation(string memory _modelId) external view returns (uint256) {
        return modelReputation[_modelId] == 0 ? 100 : modelReputation[_modelId];
    }
}
