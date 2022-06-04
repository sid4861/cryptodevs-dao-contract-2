//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract FakeNFTMarketplace {
    mapping(uint256 => address) public tokens;
    uint256 price = 0.1 ether;

    function purchase(uint256 _tokenId) public payable {
        require(msg.value == price, "not enough ether");
        tokens[_tokenId] = msg.sender;
    }

    function getPrice() external view returns (uint256) {
        return price;
    }

    function available(uint256 _tokenId) external view returns (bool) {
        if (tokens[_tokenId] == address(0)) {
            return true;
        } else {
            return false;
        }
    }
}
