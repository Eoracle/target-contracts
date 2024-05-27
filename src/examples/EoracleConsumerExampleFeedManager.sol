// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IEOFeedManager } from "../interfaces/IEOFeedManager.sol";

contract EoracleConsumerExampleFeedManager {
    // solhint-disable-next-line var-name-mixedcase
    IEOFeedManager private _feedManager;

    constructor(address feedManager) {
        _feedManager = IEOFeedManager(feedManager);
    }

    function setFeedManager(address feedManager) external {
        _feedManager = IEOFeedManager(feedManager);
    }

    function getFeedManager() external view returns (IEOFeedManager) {
        return _feedManager;
    }

    //Example for using EOFeedManager.getLatestPriceFeeds by one feed Id
    function getPrice(uint16 feedId) external view returns (IEOFeedManager.PriceFeed memory) {
        return _feedManager.getLatestPriceFeed(feedId);
    }

    //Example for using EOFeedManager.getLatestPriceFeeds with a list of feed Ids
    function getPrices(uint16[] calldata feedIds) external view returns (IEOFeedManager.PriceFeed[] memory) {
        return _feedManager.getLatestPriceFeeds(feedIds);
    }
}
