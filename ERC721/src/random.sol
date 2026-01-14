// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNFT is ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;

    event NFTMinted(uint256 tokenId, address owner, string uri);

    constructor() ERC721("MyNFT", "MNFT") Ownable(msg.sender) {}

    // ✅ Only minting
    function safeMint(string memory uri) external onlyOwner returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);

        emit NFTMinted(tokenId, msg.sender, uri);
        return tokenId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTMarketplace {
    struct Listing {
        address nftContract; // NFT kis contract ki hai
        uint256 tokenId; // NFT ka tokenId
        address seller; // seller
        uint256 price; // price in wei
    }

    // nftContract => tokenId => Listing
    mapping(address => mapping(uint256 => Listing)) public listings;

    // isListed
    mapping(address => mapping(uint256 => bool)) private isListed;

    event NFTListed(
        address nftContract,
        uint256 tokenId,
        address seller,
        uint256 price
    );

    event NFTPurchased(
        address nftContract,
        uint256 tokenId,
        address buyer,
        uint256 price
    );

    event ListingCancelled(address nftContract, uint256 tokenId);

    // ================= LIST NFT =================
    function listNFT(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external {
        require(price > 0, "Price must be > 0");

        IERC721 nft = IERC721(nftContract);

        // ✔ owner check
        require(nft.ownerOf(tokenId) == msg.sender, "Not NFT owner");

        // ✔ approval check (VERY IMPORTANT)
        require(
            nft.getApproved(tokenId) == address(this) ||
                nft.isApprovedForAll(msg.sender, address(this)),
            "Marketplace not approved"
        );

        require(!isListed[nftContract][tokenId], "Token is already listed");

        listings[nftContract][tokenId] = Listing(
            nftContract,
            tokenId,
            msg.sender,
            price
        );

        isListed[nftContract][tokenId] = true;

        emit NFTListed(nftContract, tokenId, msg.sender, price);
    }

    // ================= BUY NFT =================
    function buyNFT(address nftContract, uint256 tokenId) external payable {
        Listing memory listing = listings[nftContract][tokenId];

        require(listing.price > 0, "NFT not listed");
        require(msg.value >= listing.price, "Insufficient ETH");

        delete listings[nftContract][tokenId];
        isListed[nftContract][tokenId] = false;

        uint256 refund = msg.value - listing.price;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }

        // pay seller
        payable(listing.seller).transfer(listing.price);

        // transfer NFT
        IERC721(nftContract).safeTransferFrom(
            listing.seller,
            msg.sender,
            tokenId
        );

        emit NFTPurchased(nftContract, tokenId, msg.sender, listing.price);
    }

    // ================= CANCEL =================
    function cancelListing(address nftContract, uint256 tokenId) external {
        Listing memory listing = listings[nftContract][tokenId];

        require(listing.seller == msg.sender, "Not seller");

        delete listings[nftContract][tokenId];
        isListed[nftContract][tokenId] = false;

        emit ListingCancelled(nftContract, tokenId);
    }
}
