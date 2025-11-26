// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Events } from "./Events.sol";
import { Errors } from "./Errors.sol";


/// @title AccessManaged
/// @notice Contract ini mengatur ownership dan permission untuk semua kontrak lain
contract AccessManaged {
    /// @notice alamat pemilik kontrak
    address public owner;

    /// @notice modifier untuk membatasi fungsi hanya bisa dipanggil owner
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        if (msg.sender != owner) revert Errors.Unauthorized(msg.sender);
    }

    /// @notice constructor, owner awal = deployer
    constructor() {
        owner = msg.sender;
        emit Events.OwnershipTransferred(address(0), owner);
    }

    /// @notice ganti ownership kontrak
    /// @param newOwner alamat baru yang akan menjadi owner
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert Errors.InvalidAddress();
        address previousOwner = owner;
        owner = newOwner;
        emit Events.OwnershipTransferred(previousOwner, newOwner);
    }
}
