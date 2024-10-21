// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { EOFeedAdapterTest } from "./EOFeedAdapter.t.sol";
import { MockEOFeedManager } from "../../mock/MockEOFeedManager.sol";
import { EOFeedAdapter } from "../../../src/adapters/EOFeedAdapter.sol";
import { IEOFeedAdapter } from "../../../src/adapters/interfaces/IEOFeedAdapter.sol";
import { EOFeedRegistryAdapterClone } from "../../../src/adapters/EOFeedRegistryAdapterClone.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";

// solhint-disable ordering
// solhint-disable func-named-parameters
contract EOFeedAdapterCloneTest is EOFeedAdapterTest {
    address internal _baseAddress;
    address internal _quoteAddress;

    function setUp() public override {
        _baseAddress = makeAddr("base");
        _quoteAddress = makeAddr("quote");
        _owner = makeAddr("_owner");

        _feedManager = new MockEOFeedManager();

        IEOFeedAdapter feedAdapterImplementation =
            EOFeedAdapter(Upgrades.deployImplementation("EOFeedAdapter.sol", opts));

        EOFeedRegistryAdapterClone feedRegistryAdapter = EOFeedRegistryAdapterClone(
            Upgrades.deployTransparentProxy("EOFeedRegistryAdapterClone.sol", proxyAdmin, "")
        );
        feedRegistryAdapter.initialize(address(_feedManager), address(feedAdapterImplementation), address(this));

        _feedAdapter = EOFeedAdapter(
            address(
                feedRegistryAdapter.deployEOFeedAdapter(
                    _baseAddress, _quoteAddress, FEED_ID, DESCRIPTION, DECIMALS, DECIMALS, VERSION
                )
            )
        );
        _updatePriceFeed(FEED_ID, RATE1, block.timestamp);
        _lastTimestamp = block.timestamp;
    }
}
