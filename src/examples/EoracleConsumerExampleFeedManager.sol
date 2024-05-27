// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IEOFeedManager } from "../interfaces/IEOFeedManager.sol";

contract EoracleConsumerExampleFeedManager {
    // solhint-disable-next-line var-name-mixedcase
    IEOFeedManager private _feedManager;

    constructor(address feedManager) {
        // @audit-info Aderyn: L-3: Missing checks for address(0) when assigning values to address state variables
        _feedManager = IEOFeedManager(feedManager);
    }

    function setFeedManager(address feedManager) external {
        // @audit-info Aderyn: L-3: Missing checks for address(0) when assigning values to address state variables
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
        // @audit-info Olimpix: External Call Potential Out Of Gas
        // may cause execution to run out of gas.
        return _feedManager.getLatestPriceFeeds(feedIds);
    }
}
