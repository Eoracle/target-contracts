// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { EOFeedTest } from "./EOFeed.t.sol";
import { MockEOFeedRegistry } from "./mock/MockEOFeedRegistry.sol";
import { EOFeed } from "../src/adapters/EOFeed.sol";
import { IEOFeed } from "../src/adapters/interfaces/IEOFeed.sol";
import { EOFeedRegistryAdapter } from "../src/adapters/EOFeedRegistryAdapter.sol";

// solhint-disable ordering
// solhint-disable func-named-parameters
contract EOFeedBeaconTest is EOFeedTest {
    address internal _baseAddress;
    address internal _quoteAddress;

    function setUp() public override {
        _baseAddress = makeAddr("base");
        _quoteAddress = makeAddr("quote");
        _owner = makeAddr("_owner");

        feedRegistry = new MockEOFeedRegistry();
        IEOFeed feedImpl = new EOFeed();

        EOFeedRegistryAdapter feedRegistryAdapter = new EOFeedRegistryAdapter();
        feedRegistryAdapter.initialize(address(feedRegistry), address(feedImpl));
        feed = EOFeed(
            address(
                feedRegistryAdapter.deployEOFeed(
                    _baseAddress, _quoteAddress, _description, _description, _decimals, _version
                )
            )
        );
        feedRegistry.updatePriceFeed(_description, RATE1, block.timestamp, "");
        _lastTimestamp = block.timestamp;
    }
}
