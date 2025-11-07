// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IEscrow {
    function balanceOf(address user, address token) external view returns (uint256);
}

contract SessionRegistry {
    struct Session {
        uint256 id;
        address user;
        address tokenIn;
        address tokenOut;
        uint256 capital;
        bytes32 metadataHash;
        bool active;
    }

    uint256 public nextId;
    mapping(uint256 => Session) public sessions;
    mapping(address => uint256[]) public sessionsByUser;

    event SessionCreated(
        uint256 indexed id,
        address indexed user,
        address indexed tokenIn,
        address tokenOut,
        uint256 capital,
        bytes32 metadataHash
    );

    event SessionUpdated(
        uint256 indexed id,
        uint256 capital,
        bool active
    );

    function createSession(
        address tokenIn,
        address tokenOut,
        uint256 capital,
        bytes32 metadataHash
    ) external returns (uint256 id) {
        require(tokenIn != address(0) && tokenOut != address(0) && tokenIn != tokenOut, "bad tokens");
        require(capital > 0, "zero cap");

        id = ++nextId;

        sessions[id] = Session({
            id: id,
            user: msg.sender,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            capital: capital,
            metadataHash: metadataHash,
            active: true
        });

        sessionsByUser[msg.sender].push(id);
        emit SessionCreated(id, msg.sender, tokenIn, tokenOut, capital, metadataHash);
    }

    function setActive(uint256 id, bool active) external {
        Session storage s = sessions[id];
        require(s.user == msg.sender, "not owner");
        s.active = active;
        emit SessionUpdated(id, s.capital, active);
    }

    function setCapital(uint256 id, uint256 capital) external {
        require(capital > 0, "zero cap");
        Session storage s = sessions[id];
        require(s.user == msg.sender, "not owner");
        s.capital = capital;
        emit SessionUpdated(id, capital, s.active);
    }

    function sessionsOf(address user) external view returns (uint256[] memory) {
        return sessionsByUser[user];
    }

    // helper agar ABI lebih nyaman di FE/BE
    function getSession(uint256 id) external view returns (Session memory) {
        return sessions[id];
    }
}
