// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IEOFeedRegistry } from "../interfaces/IEOFeedRegistry.sol";

contract EoracleConsumerExampleSimple {
    IEOFeedRegistry public _feedRegistry;

    event FeedUsage(uint256 value, uint256 timestamp);

    /**
     * Network: Holesky
     * FeedRegistry: TODO - Add address
     */
    constructor() {
        _feedRegistry = IEOFeedRegistry(address(0)); //TODO - Add address
    }

    // Example for using EOFeedRegistry.getLatestPriceFeed with a single symbol.
    function getPrice() external view returns (IEOFeedRegistry.PriceFeed memory) {
        return _feedRegistry.getLatestPriceFeed(1); // 1 is the id for BTC:USD
    }

    function usePrice() external {
        IEOFeedRegistry.PriceFeed memory data = this.getPrice();
        uint256 value = data.value;
        uint256 timestamp = data.timestamp;
        // Do something
        // .............
        emit FeedUsage(value, timestamp);
    }
}
