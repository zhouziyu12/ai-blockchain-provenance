// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract AIModelNFT is ERC721, AccessControl {
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    struct ModelNFTMetadata {
        string modelId;
        string modelName;
        string version;
        uint256 accuracy;
        address creator;
        uint256 mintTimestamp;
        string ipfsHash;
    }
    
    mapping(uint256 => ModelNFTMetadata) public nftMetadata;
    mapping(string => uint256) public modelToTokenId;
    uint256 private _tokenIdCounter = 1;
    
    event ModelNFTMinted(uint256 indexed tokenId, string modelId, address indexed creator, uint256 timestamp);
    
    constructor() ERC721("AI Model NFT", "AIMNFT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }
    
    function mintModelNFT(
        address _to,
        string memory _modelId,
        string memory _modelName,
        string memory _version,
        uint256 _accuracy,
        string memory _ipfsHash
    ) external onlyRole(MINTER_ROLE) returns (uint256) {
        require(modelToTokenId[_modelId] == 0, "Model NFT already exists");
        
        uint256 tokenId = _tokenIdCounter++;
        
        nftMetadata[tokenId] = ModelNFTMetadata({
            modelId: _modelId,
            modelName: _modelName,
            version: _version,
            accuracy: _accuracy,
            creator: _to,
            mintTimestamp: block.timestamp,
            ipfsHash: _ipfsHash
        });
        
        modelToTokenId[_modelId] = tokenId;
        _safeMint(_to, tokenId);
        
        emit ModelNFTMinted(tokenId, _modelId, _to, block.timestamp);
        return tokenId;
    }
    
    function getModelNFTMetadata(uint256 _tokenId) external view returns (ModelNFTMetadata memory) {
        require(_ownerOf(_tokenId) != address(0), "Token does not exist");
        return nftMetadata[_tokenId];
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
