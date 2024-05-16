// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IEOFeedRegistry } from "../../src/interfaces/IEOFeedRegistry.sol";
import { IEOFeedVerifier } from "../../src/interfaces/IEOFeedVerifier.sol";

// solhint-disable ordering
// solhint-disable no-empty-blocks

contract MockEOFeedRegistry is IEOFeedRegistry {
    mapping(uint16 => PriceFeed) public priceFeeds;

    function updatePriceFeed(
        IEOFeedVerifier.LeafInput calldata input,
        IEOFeedVerifier.Checkpoint calldata,
        uint256[2] calldata,
        bytes calldata
    )
        external
    {
        (uint16 symbol, uint256 rate, uint256 timestamp) = abi.decode(input.unhashedLeaf, (uint16, uint256, uint256));

        priceFeeds[symbol] = PriceFeed(rate, timestamp);
    }

    function updatePriceFeeds(
        IEOFeedVerifier.LeafInput[] calldata inputs,
        IEOFeedVerifier.Checkpoint calldata,
        uint256[2] calldata,
        bytes calldata
    )
        external
    {
        for (uint256 i = 0; i < inputs.length; i++) {
            (uint16 symbol, uint256 rate, uint256 timestamp) =
                abi.decode(inputs[i].unhashedLeaf, (uint16, uint256, uint256));

            priceFeeds[symbol] = PriceFeed(rate, timestamp);
        }
    }

    function getLatestPriceFeed(uint16 symbol) external view returns (PriceFeed memory) {
        return priceFeeds[symbol];
    }

    function getLatestPriceFeeds(uint16[] memory symbols) external view returns (PriceFeed[] memory) {
        PriceFeed[] memory feeds = new PriceFeed[](symbols.length);
        for (uint256 i = 0; i < symbols.length; i++) {
            feeds[i] = priceFeeds[symbols[i]];
        }
        return feeds;
    }

    function whitelistPublishers(address[] memory, bool[] memory) external { }

    function isWhitelistedPublisher(address) external pure returns (bool) {
        return true;
    }

    function isSupportedSymbol(uint16) external view returns (bool) {
        return true;
    }
}
