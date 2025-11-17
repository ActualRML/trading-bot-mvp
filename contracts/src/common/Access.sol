// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract Access {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    constructor() {
        owner = msg.sender;
    }
}
