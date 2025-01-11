pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading
// SPDX-License-Identifier: MIT

// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
  // event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);

  YourToken public yourToken;

  uint256 public tokensPerEth = 100;

  event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
  event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH);


  constructor(address tokenAddress) {
    yourToken = YourToken(tokenAddress);
  }

  // ToDo: create a payable buyTokens() function:
     function buyTokens() public payable {
        require(msg.value > 0, "Send ETH to buy tokens");
        
        uint256 amountOfTokens = msg.value * tokensPerEth;
        
        uint256 vendorBalance = yourToken.balanceOf(address(this));
        require(vendorBalance >= amountOfTokens, "Vendor has insufficient tokens");

        bool sent = yourToken.transfer(msg.sender, amountOfTokens);
        require(sent, "Failed to transfer tokens to buyer");

        emit BuyTokens(msg.sender, msg.value, amountOfTokens);
    }

  // ToDo: create a withdraw() function that lets the owner withdraw ETH
      function sellTokens(uint256 tokenAmount) public {
        require(tokenAmount > 0, "Specify an amount of tokens greater than zero");

        uint256 userBalance = yourToken.balanceOf(msg.sender);
        require(userBalance >= tokenAmount, "Your balance is lower than the amount of tokens you want to sell");

        uint256 amountOfETH = tokenAmount / tokensPerEth;
        uint256 vendorBalance = address(this).balance;
        require(vendorBalance >= amountOfETH, "Vendor has insufficient funds");

        bool sent = yourToken.transferFrom(msg.sender, address(this), tokenAmount);
        require(sent, "Failed to transfer tokens from user to vendor");

        (bool success,) = msg.sender.call{value: amountOfETH}("");
        require(success, "Failed to send ETH to the user");

        emit SellTokens(msg.sender, tokenAmount, amountOfETH);
    }

  // ToDo: create a sellTokens(uint256 _amount) function:
      function withdraw() public onlyOwner {
        uint256 ownerBalance = address(this).balance;
        require(ownerBalance > 0, "No ETH present in vendor");
        
        (bool success,) = msg.sender.call{value: ownerBalance}("");
        require(success, "Failed to send ETH");
    }

    // Function to withdraw tokens by owner
    function withdrawTokens() public onlyOwner {
        uint256 tokenBalance = yourToken.balanceOf(address(this));
        bool sent = yourToken.transfer(msg.sender, tokenBalance);
        require(sent, "Failed to withdraw tokens");
    }
}
