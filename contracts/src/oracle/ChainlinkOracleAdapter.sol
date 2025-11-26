// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IChainlink {
    function latestAnswer() external view returns (int256);
}

contract ChainlinkOracleAdapter {
    IChainlink public feed;

    constructor(address _feed) {
        feed = IChainlink(_feed);
    }

    function getPrice() external view returns (int256) {
        return feed.latestAnswer();
    }
}
