// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Migrations {
    address public owner = msg.sender;
    uint256 public lastCompletedMigration;

    modifier restricted() {
        require(msg.sender == owner, "function restricted to owner");
        _;
    }

    function setCompleted(uint256 completed) public restricted {
        lastCompletedMigration = completed;
    }
}
