// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../libs/ReentrancyGuard.sol";

contract Escrow is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- state
    mapping(address => uint256) public deposits;

    // --- events
    event Deposited(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);

    // --- deposit token (caller must approve this contract first)
    function deposit(address token, uint amount) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        deposits[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }

    // --- withdraw token (non-reentrant)
    function withdraw(address token, uint amount) external nonReentrant {
        require(deposits[msg.sender] >= amount, "not enough");
        deposits[msg.sender] -= amount;
        IERC20(token).safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }
}
