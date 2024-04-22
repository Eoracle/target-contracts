// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IEoracle} from "./interfaces/IEoracle.sol";

contract EoracleConsumer {
    // solhint-disable-next-line var-name-mixedcase
    IEoracle public Eoracle = IEoracle(0x62D43C799Fe0ECAAb59a3A084cA749D2E613D7a8);

    event PriceFeedUsage(string symbol, uint256 value, uint256 timestamp);

    //Example for calling an Eoracle.updateFeeds (with a single symbol) and then using the results
    function updateAndGetPriceFeed(
        string calldata symbol,
        uint256 value,
        uint256 timestamp,
        bytes memory proofData
    ) external {
        Eoracle.updatePriceFeed(symbol, value, timestamp, proofData);
        IEoracle.PriceFeed memory priceFeed = Eoracle.getLatestPriceFeed(symbol);
        // How to read the quotes from the Eoracle.getLatestFeed output.
        emit PriceFeedUsage(symbol, priceFeed.value, priceFeed.timestamp);
    }

    //Example for using Eoracle.getLatestFeeds with a list of symbols.
    function getLatestPriceFeeds(string[] calldata symbols) external view returns (IEoracle.PriceFeed[] memory) {
        return Eoracle.getLatestPriceFeeds(symbols);
    }
}
