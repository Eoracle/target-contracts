// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IEOFeedRegistry } from "../interfaces/IEOFeedRegistry.sol";

contract EoracleConsumerExampleFeedRegistry {
    // solhint-disable-next-line var-name-mixedcase
    IEOFeedRegistry private _feedRegistry;

    constructor(address feedRegistry) {
        _feedRegistry = IEOFeedRegistry(feedRegistry);
    }

    function setFeedRegistry(address feedRegistry) external {
        _feedRegistry = IEOFeedRegistry(feedRegistry);
    }

    function getFeedRegistry() external view returns (IEOFeedRegistry) {
        return _feedRegistry;
    }

    //Example for using EOFeedRegistry.getLatestPriceFeeds with a list of symbols.
    function getPrice(uint16 symbol) external view returns (IEOFeedRegistry.PriceFeed memory) {
        return _feedRegistry.getLatestPriceFeed(symbol);
    }

    //Example for using EOFeedRegistry.getLatestPriceFeeds with a list of symbols.
    function getPrices(uint16[] calldata symbols) external view returns (IEOFeedRegistry.PriceFeed[] memory) {
        return _feedRegistry.getLatestPriceFeeds(symbols);
    }
}
