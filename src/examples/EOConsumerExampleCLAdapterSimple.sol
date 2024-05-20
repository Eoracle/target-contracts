// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IEOFeed } from "../adapters/interfaces/IEOFeed.sol";

contract EoracleConsumerExampleFeed {
    IEOFeed public _feed;

    event FeedUsage(uint256 value, uint256 timestamp);

    constructor() {
        _feed = IEOFeed(address(0)); //TODO add address
    }

    /**
     * Network: Holesky
     * FeedRegistry: TODO - Add address
     */
    function usePrice() external {
        int256 value = this.getPrice();
        // Do something
        // .............
        emit FeedUsage(uint256(value), block.timestamp);
    }

    function getPrice() external view returns (int256 answer) {
        (, answer,,,) = _feed.latestRoundData();
    }
}
