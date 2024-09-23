// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { EOFeedRegistryAdapterBaseTest } from "./EOFeedRegistryAdapterBase.t.sol";
import { EOFeedRegistryAdapterBase } from "../../../src/adapters/EOFeedRegistryAdapterBase.sol";
import { EOFeedRegistryAdapterClone } from "../../../src/adapters/EOFeedRegistryAdapterClone.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";

// solhint-disable ordering
contract EOFeedRegistryAdapterCloneTest is EOFeedRegistryAdapterBaseTest {
    function _deployAdapter() internal override returns (EOFeedRegistryAdapterBase) {
        return EOFeedRegistryAdapterBase(
            Upgrades.deployTransparentProxy("EOFeedRegistryAdapterClone.sol", _proxyAdmin, "")
        );
    }

    function test_FactoryInitialized() public view override {
        assertEq(
            address(EOFeedRegistryAdapterClone(address(_feedRegistryAdapter)).getFeedAdapterImplementation()),
            address(_feedAdapterImplementation)
        );
    }
}
