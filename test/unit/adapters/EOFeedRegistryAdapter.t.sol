// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { EOFeedRegistryAdapterBaseTest } from "./EOFeedRegistryAdapterBase.t.sol";
import { EOFeedRegistryAdapterBase } from "../../../src/adapters/EOFeedRegistryAdapterBase.sol";
import { EOFeedRegistryAdapter } from "../../../src/adapters/EOFeedRegistryAdapter.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";

// solhint-disable ordering
contract EOFeedRegistryAdapterTest is EOFeedRegistryAdapterBaseTest {
    function _deployAdapter(bytes memory initData) internal override returns (EOFeedRegistryAdapterBase) {
        return EOFeedRegistryAdapterBase(
            Upgrades.deployTransparentProxy("EOFeedRegistryAdapter.sol", proxyAdmin, initData)
        );
    }

    function test_FactoryInitialized() public view override {
        assertEq(
            address(UpgradeableBeacon(EOFeedRegistryAdapter(address(_feedRegistryAdapter)).getBeacon()).owner()),
            address(this)
        );
        assertEq(
            address(
                UpgradeableBeacon(EOFeedRegistryAdapter(address(_feedRegistryAdapter)).getBeacon()).implementation()
            ),
            address(_feedAdapterImplementation)
        );
    }
}
