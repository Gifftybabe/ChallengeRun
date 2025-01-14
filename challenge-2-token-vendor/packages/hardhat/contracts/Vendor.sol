// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vendor is Ownable {
    IERC20 public yourToken;
    uint256 public constant tokensPerEth = 100;

    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH);

    constructor(address tokenAddress) {
        yourToken = IERC20(tokenAddress);
    }

    function buyTokens() public payable {
        require(msg.value > 0, "Send ETH to buy tokens");
        
        // Calculate tokens to buy (needs to account for decimals)
        uint256 amountToBuy = (msg.value * tokensPerEth * 10**18) / 1 ether; // Fixed calculation
        uint256 vendorBalance = yourToken.balanceOf(address(this));
        require(vendorBalance >= amountToBuy, "Vendor has insufficient tokens");

        bool sent = yourToken.transfer(msg.sender, amountToBuy);
        require(sent, "Token transfer failed");

        emit BuyTokens(msg.sender, msg.value, amountToBuy);
    }

    function sellTokens(uint256 tokenAmount) public {
        require(tokenAmount > 0, "Specify an amount of tokens greater than zero");
        require(yourToken.allowance(msg.sender, address(this)) >= tokenAmount, "Check the token allowance");
        
        // Calculate ETH to return (needs to account for decimals)
        uint256 ethToReturn = (tokenAmount * 1 ether) / (tokensPerEth * 10**18); // Fixed calculation
        require(address(this).balance >= ethToReturn, "Vendor has insufficient ETH balance");
        
        bool sent = yourToken.transferFrom(msg.sender, address(this), tokenAmount);
        require(sent, "Token transfer failed");
        
        (bool success,) = msg.sender.call{value: ethToReturn}("");
        require(success, "ETH transfer failed");
        
        emit SellTokens(msg.sender, tokenAmount, ethToReturn);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        
        (bool success,) = msg.sender.call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    function checkAllowance(address owner) public view returns (uint256) {
        return yourToken.allowance(owner, address(this));
    }
}