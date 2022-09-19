// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";  //gain access to the ERC-721 smart contract standard
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";   //saves details about the digital asset
import "@openzeppelin/contracts/utils/Counters.sol";  //Allows us to gain access to a counter utility that makes it easy to create a counter anytime a function is called
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";  // Gives access to a modifying that prevents reentry during recursive calls

import "hardhat/console.sol";




// Defining my NFT Smart Contract
contract NFT is ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;  //Declaring a variable tokenIds(0 by default)
    address contractAddress;  


    constructor(address marketplaceAddress) ERC721("TriBBBal's Digital Marketplace", "TBM") {
        contractAddress = marketplaceAddress;

    }

    function createToken(string memory tokenURI) public returns (uint) {
        _tokenIds.increment(); 
        uint256 newItemId = _tokenIds.current();  //creating a new token Id

        _mint(msg.sender, newItemId); //Minting Token
        _setTokenURI(newItemId, tokenURI);  
        setApprovalForAll(contractAddress, true);

        return newItemId; //This serves like a primary key to retrieve infomation from the contract

    }
}



//Defining my NFT Marketplace smart contract
contract NFTMarket is ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _itemIds; //keep track of the NFTs in the marketplace
    Counters.Counter private _itemsSold;  //keeps track of items being sold in the marketplace


    address payable owner;
    uint256 listingPrice = 0.07 ether;


    constructor() {
        owner = payable(msg.sender);
    }

    struct MarketItem {  //keeping track of the market item 
        uint itemId;
        address nftContract; //address of the digital token
        uint256 tokenId;
        address payable seller; //the seller(the current owner of the item)
        address payable owner; //the new owner of the market iteem after purchase
        uint256 price;
        bool sold;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;


    event MarketItemCreated (
        uint indexed itemId ,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    } 

    //Putting(Creating) market item up for sale
    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant { 
        require(price > 0, "Price must be least 1 wei");
        require(msg.value == listingPrice, "Price must be equal to listing price");
        
        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );

        //Transfering ownership of the token to buyer
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        
        emit MarketItemCreated(itemId, nftContract, tokenId, msg.sender, address(0), price, false);


    }

    //creating a selling strem of the marketItem
    function createMarketSale(
        address nftContract,
        uint256 itemId

    ) public payable nonReentrant {
        uint price = idToMarketItem[itemId].price;
        uint tokenId = idToMarketItem[itemId].tokenId;

        // checking for the required amount being paid for the token
        require(msg.value == price, "Please submit the asking price in order to complete the purchase");

        idToMarketItem[itemId].seller.transfer(msg.value);
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);  //Transfering assest to buyer
        idToMarketItem[itemId].owner = payable(msg.sender);  //changing the state value of "owner" to the new owner
        idToMarketItem[itemId].sold = true; //defining token as sold
        _itemsSold.increment();
        payable(owner).transfer(listingPrice);

    }


    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint itemCount = _itemIds.current();   
        uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
        
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint i = 0; i < itemCount; i++) {
            if(idToMarketItem[i + 1].owner == address(0)) {
                uint currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }

            
        }

        return items;
    }

    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
            
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
            for (uint i = 0; i < totalItemCount; i++) {
            if(idToMarketItem[i + 1].owner == msg.sender) {
                uint currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }

            
        }

        return items;

    }

    function fetchItemsCreated() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
            
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if(idToMarketItem[i + 1].seller == msg.sender) {
                uint currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }

            
        }
        return items;
    }


}


