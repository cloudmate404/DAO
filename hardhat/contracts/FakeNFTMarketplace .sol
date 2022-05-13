// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract FakeNFTMarketplace{
    // create a mapping that shows ownership of a token to an address
    mapping(uint => address) public tokens;

    // price of each FAke NFT
    uint nftPrice = 0.01 ether;

    //create a function that executes purchase and assigns ownership of a the bought token to the caller
    function purchase(uint _tokenId) external payable {
        require(msg.value == nftPrice, "Ether sent is correct");
        tokens[_tokenId] = msg.sender;
    }

    // create function that getPrice of NFT by returning nftPrice 
    function getPrice() external view returns(uint) {
        return nftPrice;
    }

    // create function that checks whether the given tokenId has already been sold or not
    function available(uint _tokenId) external view returns (bool){
        if(tokens[_tokenId] == address(0)){
            return true;
        }
    }
}