// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;


contract AccessManaged {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(
            address(0),
            msg.sender
        );
    }


    modifier onlyOwner() {
    _onlyOwner();
    _;
    }

    function _onlyOwner() internal view {
        require(msg.sender == owner, "AccessManaged: caller is not owner");
    }


    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "AccessManaged: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}