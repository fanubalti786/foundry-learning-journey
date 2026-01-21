// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTMarketplace {
    struct Listing {
        address nftContract;
        uint256 tokenId;
        address seller;
        uint256 price;
        // 🔥 active removed
    }

    // nftContract => tokenId => Listing
    mapping(address => mapping(uint256 => Listing)) public listings;

    // array to track all listings
    Listing[] public allListings;

    // ================= EVENTS =================
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
        require(nft.ownerOf(tokenId) == msg.sender, "Not NFT owner");
        require(
            nft.getApproved(tokenId) == address(this) ||
                nft.isApprovedForAll(msg.sender, address(this)),
            "Marketplace not approved"
        );

        Listing storage listing = listings[nftContract][tokenId];
        require(listing.seller == address(0), "Already listed");

        listing.nftContract = nftContract;
        listing.tokenId = tokenId;
        listing.seller = msg.sender;
        listing.price = price;

        allListings.push(listing);

        emit NFTListed(nftContract, tokenId, msg.sender, price);
    }

    // ================= BUY NFT =================
    function buyNFT(address nftContract, uint256 tokenId) external payable {
        Listing storage listing = listings[nftContract][tokenId];

        require(listing.seller != address(0), "NFT not listed");

        // 🔥 Ownership check
        address currentOwner = IERC721(nftContract).ownerOf(tokenId);
        require(currentOwner == listing.seller, "NFT already sold elsewhere");

        require(msg.value >= listing.price, "Incorrect ETH amount");

        // Transfer ETH
        payable(listing.seller).transfer(listing.price);

        // Refund extra ETH
        uint256 refund = msg.value - listing.price;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }

        // Transfer NFT
        IERC721(nftContract).safeTransferFrom(
            listing.seller,
            msg.sender,
            tokenId
        );

        // Remove listing from mapping (cleanup)
        delete listings[nftContract][tokenId];

        emit NFTPurchased(
            nftContract,
            tokenId,
            msg.sender,
            listing.price
        );
    }

    // ================= CANCEL LISTING =================
    function cancelListing(address nftContract, uint256 tokenId) external {
        Listing storage listing = listings[nftContract][tokenId];
        require(listing.seller == msg.sender, "Not seller");

        delete listings[nftContract][tokenId];

        emit ListingCancelled(nftContract, tokenId);
    }

    // ================= GET ACTIVE LISTINGS =================
    function getActiveListingsView() external view returns (Listing[] memory) {
        uint256 len = allListings.length;
        Listing[] memory temp = new Listing[](len);
        uint256 index = 0;

        for (uint256 i = 0; i < len; i++) {
            Listing storage l = listings[allListings[i].nftContract][
                allListings[i].tokenId
            ];

            // Skip removed / sold NFTs
            if (l.seller == address(0)) continue;

            // Skip NFTs sold elsewhere
            try IERC721(l.nftContract).ownerOf(l.tokenId) returns (address owner) {
                if (owner != l.seller) continue;
            } catch {
                continue;
            }

            temp[index] = l;
            index++;
        }

        assembly {
            mstore(temp, index)
        }

        return temp;
    }
}