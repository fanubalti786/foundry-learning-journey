// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FanuToken is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    uint256 private _nextTokenId;

    // 🔔 Events
    event NFTMinted(uint256 indexed tokenId, address indexed to, string uri);
    event NFTBurned(uint256 indexed tokenId, address indexed owner);

    constructor() ERC721("MyToken", "MTK") {}

    // ================== Minting ==================

    // ✅ Single mint (decentralized)
    function safeMint(string memory uri) external returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);

        emit NFTMinted(tokenId, msg.sender, uri);
        return tokenId;
    }

    // ✅ Batch mint
    function batchMint(string[] memory uris) external {
        for (uint256 i = 0; i < uris.length; i++) {
            uint256 tokenId = _nextTokenId++;
            _safeMint(msg.sender, tokenId);
            _setTokenURI(tokenId, uris[i]);

            emit NFTMinted(tokenId, msg.sender, uris[i]);
        }
    }

    // ================== Burn ==================

    // ✅ Burn with event (permission checked internally)
    function burnWithEvent(uint256 tokenId) external {
        address tokenOwner = ownerOf(tokenId);
        burn(tokenId); // ERC721Burnable → owner/approved check
        emit NFTBurned(tokenId, tokenOwner);
    }

    // ================== Marketplace Approvals ==================

    // ✅ Approve single token for marketplace
    function approveMarketplaceForToken(address marketplace, uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        approve(marketplace, tokenId);
    }

    // ✅ Approve all tokens for marketplace
    function approveMarketplace(address marketplace) external {
        setApprovalForAll(marketplace, true); // msg.sender = owner internally
    }

    // ✅ Check single token approval
    function isTokenApproved(uint256 tokenId, address operator) external view returns (bool) {
        return getApproved(tokenId) == operator;
    }

    // ✅ Check all tokens approval
    function isApproved(address owner, address operator) external view returns (bool) {
        return isApprovedForAll(owner, operator);
    }

    // ================== Helpers ==================

    // ✅ Check if token exists
    function exists(uint256 tokenId) external view returns (bool) {
        return exists(tokenId);
    }

    // ✅ Total supply (number of minted NFTs)
    function totalSupply() external view returns (uint256) {
        return _nextTokenId;
    }

    // ================== Overrides ==================

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}