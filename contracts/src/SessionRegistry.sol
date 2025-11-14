// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import {AccessManaged} from "./utils/AccessManaged.sol";


contract SessionRegistry is AccessManaged {
    struct Session {
        address user;
        uint256 startTime;
        bool active;
    }

    mapping(address => Session) private sessions;

    event SessionStarted(address indexed user, uint256 startTime);
    event SessionEnded(address indexed user, uint256 endTime);

    function startSession() external {
        Session storage s = sessions[msg.sender];
        require(!s.active, "SessionRegistry: session already active");
            s.user = msg.sender;
            s.startTime = block.timestamp;
            s.active = true;
        emit SessionStarted(msg.sender, s.startTime);
    }


    function endSession() external {
        Session storage s = sessions[msg.sender];
        require(s.active, "SessionRegistry: no active session");
            s.active = false;
        emit SessionEnded(msg.sender, block.timestamp);
    }


    function isActive(address user) external view returns (bool) {
        return sessions[user].active;
    }
}