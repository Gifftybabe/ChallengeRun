
// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;
    uint256 public deadline;
    uint256 public constant threshold = 1 ether;

    mapping(address => uint256) public balances;
    bool public executed;

    event Stake(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event ExecutionSuccess(uint256 totalStaked);
    event ExecutionFailure(uint256 totalStaked);

    constructor(address exampleExternalContractAddress) {
        require(exampleExternalContractAddress != address(0), "address zero detected");
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
        deadline = block.timestamp + 72 hours;
        
        console.log("Staker contract deployed at:", address(this));
        console.log("External contract address:", exampleExternalContractAddress);
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)
    function stake() public payable {
        require(!exampleExternalContract.completed(), "Staking is completed");
        require(block.timestamp < deadline, "Staking period has ended");
        require(msg.value > 0, "You must send ETH to stake");

        balances[msg.sender] += msg.value;
        
        console.log("Stake successful - Amount:", msg.value);
        console.log("New balance for", msg.sender, ":", balances[msg.sender]);
        
        emit Stake(msg.sender, msg.value);
    }

    // function execute() public {
    //     require(block.timestamp >= deadline, "Deadline has not been reached");
    //     require(!executed, "Contract has already been executed");
    //     require(!exampleExternalContract.completed(), "External contract already completed");
        
    //     uint256 contractBalance = address(this).balance;
    //     require(contractBalance >= threshold, "Threshold not met, use withdraw instead");
        
    //     executed = true;
        
    //     console.log("Threshold met! Sending", contractBalance, "to external contract");
    //     exampleExternalContract.complete{value: contractBalance}();
    //     emit ExecutionSuccess(contractBalance);
    // }


    // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
    function execute() public {
    require(block.timestamp >= deadline, "Deadline has not been reached");
    require(!executed, "Contract has already been executed");
    require(!exampleExternalContract.completed(), "External contract already completed");

    uint256 contractBalance = address(this).balance;

    if (contractBalance >= threshold) {
        exampleExternalContract.complete{value: contractBalance}();
        emit ExecutionSuccess(contractBalance);
    } else {
        emit ExecutionFailure(contractBalance);
    }

    executed = true; 
}


    // function withdraw() public {
    //     require(block.timestamp >= deadline, "Deadline has not been reached");
    //     require(!exampleExternalContract.completed(), "Staking was successful, cannot withdraw");
    //     require(balances[msg.sender] > 0, "No balance to withdraw");
        
     
    //     require(
    //         address(this).balance < threshold || executed,
    //         "Cannot withdraw while threshold is met and execution is still possible"
    //     );

    //     uint256 amount = balances[msg.sender];
    //     balances[msg.sender] = 0;

    //     console.log("Withdrawing", amount, "to", msg.sender);
        
    //     (bool success, ) = msg.sender.call{value: amount}("");
    //     require(success, "Withdrawal failed");
        
    //     emit Withdrawal(msg.sender, amount);
    // }

      // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
    function withdraw() public {
    require(block.timestamp >= deadline, "Deadline has not been reached");
    require(!exampleExternalContract.completed(), "Staking was successful, cannot withdraw");
    require(balances[msg.sender] > 0, "No balance to withdraw");
    require(executed, "Execute function must be called first");

    uint256 amount = balances[msg.sender];
    balances[msg.sender] = 0;

    console.log("Withdrawing", amount, "to", msg.sender);

    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Withdrawal failed");

    emit Withdrawal(msg.sender, amount);
}

      // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        require(!exampleExternalContract.completed(), "Staking is completed");
        require(block.timestamp < deadline, "Staking period has ended");
        
        balances[msg.sender] += msg.value;
        
        console.log("Received", msg.value, "from", msg.sender);
        
        emit Stake(msg.sender, msg.value);
    }

      // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }

    modifier notCompleted() {
        require(!exampleExternalContract.completed(), "ExampleExternalContract already completed");
        _;
    }
}