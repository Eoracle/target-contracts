// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IEOFeedRegistry } from "./interfaces/IEOFeedRegistry.sol";
import { IEOFeedVerifier } from "./interfaces/IEOFeedVerifier.sol";

contract EoracleConsumer {
    // solhint-disable-next-line var-name-mixedcase
    IEOFeedRegistry public EOFeedRegistry = IEOFeedRegistry(0x62D43C799Fe0ECAAb59a3A084cA749D2E613D7a8);

    event PriceFeedUsage(uint16 symbol, uint256 value, uint256 timestamp);

    //Example for calling an EOFeedRegistry.updateFeeds (with a single symbol) and then using the results
    function updateAndGetPriceFeed(bytes calldata rateData, bytes memory checkpointData) external {
        (uint256 blockNumber, uint256 leafIndex, bytes memory unhashedLeaf, bytes32[] memory proof) =
            abi.decode(rateData, (uint256, uint256, bytes, bytes32[]));
        IEOFeedVerifier.LeafInput memory input = IEOFeedVerifier.LeafInput(blockNumber, leafIndex, unhashedLeaf, proof);

        (uint16 symbol, uint256 rate, uint256 timestamp) = abi.decode(unhashedLeaf, (uint16, uint256, uint256));

        EOFeedRegistry.updatePriceFeed(input, checkpointData);
        IEOFeedRegistry.PriceFeed memory priceFeed = EOFeedRegistry.getLatestPriceFeed(symbol);
        require(priceFeed.timestamp == timestamp, "INVALID_TIMESTAMP");
        require(priceFeed.value == rate, "INVALID_RATE");
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
