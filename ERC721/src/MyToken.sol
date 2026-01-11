// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.5.0
pragma solidity ^0.8.27;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC721, ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;
    uint256[] private listedTokenIds;

    struct Listing {
        address seller;
        uint256 price;
    }

    mapping (uint256 => Listing) public listings;
    event NFTMinted(uint256 tokenId, address owner, string uri);
    event NFTListed(uint256 tokenId, address seller, uint256 price);
    event ListingCancelled(uint256 tokenId);
    event NFTPurchased(uint256 tokenId, address buyer, uint256 price);


    constructor(address initialOwner)
        ERC721("MyToken", "MTK")
        Ownable(initialOwner)
    {}

    function safeMint(string memory uri)
        public
        onlyOwner
        returns (uint256)
    {
        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
        emit NFTMinted(tokenId, msg.sender, uri);
        return tokenId;
    }

    function listing(uint256 tokenId, uint256 price) public {
        require(price > 0, "Price must be greater than 0");
        require(ownerOf(tokenId) == msg.sender, "you are not the owner of this token");
        // require(listedTokenIds[tokenId] == false, "Token is already listed");
        listings[tokenId] = Listing(msg.sender,price);
        listedTokenIds.push(tokenId);
    }


    function buyNFT(uint256 tokenId) external payable{

        Listing memory listing = listings[tokenId];
        require(listing.price > 0, "NFT not listed");
        require(listing.price <= msg.value, "insufficient funds");
        delete listings[tokenId];
        removeTokenFromListed(tokenId);

        payable(listing.seller).transfer(listing.price);
        // Transfer the NFT to the buyer
        _transfer(listing.seller, msg.sender, tokenId);
        emit NFTPurchased(tokenId, msg.sender, listing.price);
        


    }

    function cancelListing(uint256 tokenId) external {
        Listing memory listing = listings[tokenId];
        require(listing.seller == msg.sender, "you are not the owner of this token");
        delete listings[tokenId];
        removeTokenFromListed(tokenId);
        emit ListingCancelled(tokenId);
    }



    function removeTokenFromListed(uint256 tokenId) internal {
        for(uint i=0; i<listedTokenIds.length; i++)
        {
            if(listedTokenIds[i] == tokenId)
            {
                listedTokenIds[i] = listedTokenIds.length - 1;
                listedTokenIds.pop();
                break;
            }
        }
    }


    function getAllListings() external view returns (Listing[] memory, uint256[] memory tokenId) {
        uint256 count = listedTokenIds.length;
        Listing[] memory activeListings = new Listing[](count);
        uint256[] memory tokenIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = listedTokenIds[i];
            activeListings[i] = listings[tokenId];
            tokenIds[i] = tokenId;
        }

        return(activeListings,tokenId);
    }

    

    // The following functions are overrides required by Solidity.
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