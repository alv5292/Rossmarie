// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract RossmariePass is ERC721Enumerable, AccessControl, Pausable {
    bytes32 public constant ADMIN_ROLE = DEFAULT_ADMIN_ROLE;
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    string private tokenURIValue;
    uint256 private _tokenIdCounter;
    mapping(address => bool) public hasMinted;

    /// @dev If true, disallows transfers (Soulbound mode)
    bool public transfersLocked;

    event Minted(address indexed to, uint256 tokenId, uint256 timestamp);
    event Burned(address indexed by, uint256 tokenId, uint256 timestamp);
    event TransfersLocked(bool locked);

    constructor(string memory _tokenURI) ERC721("Rossmarie Member Pass", "RMP") {
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);

        tokenURIValue = _tokenURI;
        transfersLocked = true; // Start soulbound by default
    }

    function mint() external whenNotPaused {
        require(!hasMinted[msg.sender], "Only one pass per wallet");

        _tokenIdCounter++;
        uint256 tokenId = _tokenIdCounter;

        _safeMint(msg.sender, tokenId);
        hasMinted[msg.sender] = true;

        emit Minted(msg.sender, tokenId, block.timestamp);
    }

    function burn(uint256 tokenId) external whenNotPaused {
        address owner = ownerOf(tokenId);
        require(
            _msgSender() == owner ||
            getApproved(tokenId) == _msgSender() ||
            isApprovedForAll(owner, _msgSender()) ||
            hasRole(BURNER_ROLE, _msgSender()),
            "Not authorized to burn"
        );

        _burn(tokenId);
        hasMinted[owner] = false;

        emit Burned(msg.sender, tokenId, block.timestamp);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Nonexistent token");
        return tokenURIValue;
    }

    function setTokenURI(string memory _newTokenURI) external onlyRole(ADMIN_ROLE) {
        tokenURIValue = _newTokenURI;
    }

    function lockTransfers(bool _locked) external onlyRole(ADMIN_ROLE) {
        transfersLocked = _locked;
        emit TransfersLocked(_locked);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function totalMinted() public view returns (uint256) {
        return _tokenIdCounter;
    }

    /// @dev Override transfer functions to respect `transfersLocked`
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override
        whenNotPaused
    {
        if (transfersLocked && from != address(0) && to != address(0)) {
            revert("Soulbound: transfers disabled");
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
