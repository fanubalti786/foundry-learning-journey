// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.5.0
pragma solidity ^0.8.27;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {
    ERC721URIStorage
} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC721, ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;
    uint256[] private listedTokenIds;

    struct Listing {
        address seller;
        uint256 price;
    }

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => bool) private isListed;
    event NFTMinted(uint256 tokenId, address owner, string uri);
    event NFTListed(uint256 tokenId, address seller, uint256 price);
    event ListingCancelled(uint256 tokenId);
    event NFTPurchased(uint256 tokenId, address buyer, uint256 price);

    constructor(
        address initialOwner
    ) ERC721("MyToken", "MTK") Ownable(initialOwner) {}

    function safeMint(string memory uri) public onlyOwner returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
        emit NFTMinted(tokenId, msg.sender, uri);
        return tokenId;
    }

    function listing(uint256 tokenId, uint256 price) public {
        require(price > 0, "Price must be greater than 0");
        require(
            ownerOf(tokenId) == msg.sender,
            "you are not the owner of this token"
        );
        require(!isListed[tokenId], "Token is already listed");
        listings[tokenId] = Listing(msg.sender, price);
        listedTokenIds.push(tokenId);
        isListed[tokenId] = true;
        emit NFTListed(tokenId, msg.sender, price);
    }

   function buyNFT(uint256 tokenId) external payable {
    Listing memory listing = listings[tokenId];

    require(listing.price > 0, "NFT not listed");
    require(msg.value >= listing.price, "Insufficient funds");

    // ===== EFFECTS (state updates first) =====
    delete listings[tokenId];
    isListed[tokenId] = false;
    removeTokenFromListed(tokenId);

    // ===== INTERACTIONS =====
    payable(listing.seller).transfer(listing.price);

    uint256 refund = msg.value - listing.price;
    if (refund > 0) {
        payable(msg.sender).transfer(refund);
    }

    // NFT transfer
    _transfer(listing.seller, msg.sender, tokenId);

    emit NFTPurchased(tokenId, msg.sender, listing.price);
}


    function cancelListing(uint256 tokenId) external {
        Listing memory listing = listings[tokenId];
        require(
            listing.seller == msg.sender,
            "you are not the owner of this token"
        );
        delete listings[tokenId];
        isListed[tokenId] = false;
        removeTokenFromListed(tokenId);
        emit ListingCancelled(tokenId);
    }

    function removeTokenFromListed(uint256 tokenId) internal {
        for (uint256 i = 0; i < listedTokenIds.length; i++) {
            if (listedTokenIds[i] == tokenId) {
                listedTokenIds[i] = listedTokenIds[listedTokenIds.length - 1];
                listedTokenIds.pop();
                break;
            }
        }
    }

    function getAllListings()
    external
    view
    returns (address[] memory sellers, uint256[] memory prices, uint256[] memory tokenIds)
{
    uint256 count = listedTokenIds.length;
    address[] memory _sellers = new address[](count);
    uint256[] memory _prices = new uint256[](count);
    uint256[] memory _tokenIds = new uint256[](count);

    for (uint256 i = 0; i < count; i++) {
        uint256 id = listedTokenIds[i];
        _sellers[i] = listings[id].seller;
        _prices[i] = listings[id].price;
        _tokenIds[i] = id;
    }

    return (_sellers, _prices, _tokenIds);
}


    // The following functions are overrides required by Solidity.
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
