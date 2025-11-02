// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SessionRegistry {
    struct Session {
        uint id;
        address user;
        string symbol;
        uint256 capital;
        bytes32 metadataHash;
        bool active;
    }

    uint public nextId;
    mapping(uint => Session) public sessions;
    event SessionCreated(uint id, address indexed user, string symbol, uint capital, bytes32 metadataHash);

    function createSession(string calldata symbol, uint capital, bytes32 metadataHash) external returns (uint) {
        uint id = ++nextId;
        sessions[id] = Session(id, msg.sender, symbol, capital, metadataHash, true);
        emit SessionCreated(id, msg.sender, symbol, capital, metadataHash);
        return id;
    }
}
