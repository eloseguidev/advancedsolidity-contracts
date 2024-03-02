// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


contract MarketPlace2 is ReentrancyGuard{

    address payable public immutable feeAccount; 
    uint public immutable feePercent; 

    uint public tokenCount;

    struct Token {
        uint tokenID;
        IERC721 nft;
        uint nftID;
        uint price;
        address payable seller;
        bool sold;
    }

    mapping (uint=> Token) public tokens; 

    event Offered (uint tokenID, address indexed nft, uint nftID, uint price, address indexed seller);
    event Bought (uint tokenID, address indexed nft, uint nftID, address indexed seller, address indexed buyer);

    constructor (uint _feePercent) {
        feeAccount = payable(msg.sender);
        feePercent = _feePercent;
    }

    function offerToken (IERC721 _nft, uint _nftID, uint _price) external nonReentrant {
        require(_price > 0, "Invalid price");
        tokenCount++;

        _nft.transferFrom(msg.sender, address(this), _nftID);

        tokens [tokenCount] = Token(tokenCount, _nft, _nftID, _price, payable(msg.sender), false);

        emit Offered (tokenCount,address(_nft), _nftID, _price, msg.sender);

    }

    function getPrice(uint _tokenID) view public returns (uint) {
        return((tokens[_tokenID].price*(100+feePercent))/100);
    }


    function purchaseToken (uint _tokenID) external payable nonReentrant {
        require (_tokenID > 0 && _tokenID <= tokenCount, "Non exist");
        uint totalPrice = getPrice(_tokenID); 
        require(msg.value >= totalPrice, "Insuffient ethers");

        Token storage saleToken = tokens[_tokenID];

        require(!saleToken.sold);

        saleToken.seller.transfer(saleToken.price); 

        feeAccount.transfer(totalPrice-saleToken.price);

        saleToken.sold = true; 

        saleToken.nft.transferFrom(address(this), msg.sender, saleToken.nftID);

        emit Bought(saleToken.tokenID, address(saleToken.nft), saleToken.nftID, saleToken.seller, msg.sender);


    }



}