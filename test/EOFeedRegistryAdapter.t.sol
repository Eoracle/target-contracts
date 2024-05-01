// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { EOFeedRegistryAdapterBaseTest } from "./EOFeedRegistryAdapterBase.t.sol";
import { EOFeedRegistryAdapterBase } from "../src/adapters/EOFeedRegistryAdapterBase.sol";
import { EOFeedRegistryAdapter } from "../src/adapters/EOFeedRegistryAdapter.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

// solhint-disable ordering
contract EOFeedRegistryAdapterTest is EOFeedRegistryAdapterBaseTest {
    function _deployAdapter() internal override returns (EOFeedRegistryAdapterBase) {
        return EOFeedRegistryAdapterBase(new EOFeedRegistryAdapter());
    }

    function test_FactoryInitialized() public view override {
        assertEq(
            address(UpgradeableBeacon(EOFeedRegistryAdapter(address(feedRegistryAdapter)).getBeacon()).owner()),
            address(this)
        );
        assertEq(
            address(UpgradeableBeacon(EOFeedRegistryAdapter(address(feedRegistryAdapter)).getBeacon()).implementation()),
            address(feedImpl)
        );
    }
}
