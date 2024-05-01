// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IEOFeedRegistry } from "./interfaces/IEOFeedRegistry.sol";

contract EoracleConsumer {
    // solhint-disable-next-line var-name-mixedcase
    IEOFeedRegistry public EOFeedRegistry = IEOFeedRegistry(0x62D43C799Fe0ECAAb59a3A084cA749D2E613D7a8);

    event PriceFeedUsage(uint16 symbol, uint256 value, uint256 timestamp);

    //Example for calling an EOFeedRegistry.updateFeeds (with a single symbol) and then using the results
    function updateAndGetPriceFeed(
        uint16 symbol,
        uint256, /*value*/
        uint256, /*timestamp*/
        bytes memory proofData
    )
        external
    {
        EOFeedRegistry.updatePriceFeed(proofData);
        IEOFeedRegistry.PriceFeed memory priceFeed = EOFeedRegistry.getLatestPriceFeed(symbol);
        // How to read the quotes from the EOFeedRegistry.getLatestFeed output.
        emit PriceFeedUsage(symbol, priceFeed.value, priceFeed.timestamp);
    }

    //Example for using EOFeedRegistry.getLatestFeeds with a list of symbols.
    function getLatestPriceFeeds(uint16[] calldata symbols)
        external
        view
        returns (IEOFeedRegistry.PriceFeed[] memory)
    {
        return EOFeedRegistry.getLatestPriceFeeds(symbols);
    }
}
