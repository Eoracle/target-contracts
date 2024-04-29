// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { EOFeedFactoryBase } from "./EOFeedFactoryBase.sol";

abstract contract EOFeedFactoryBeacon is Initializable, EOFeedFactoryBase {
    address private _beacon;

    function getBeacon() external view returns (address) {
        return _beacon;
    }

    function __EOFeedFactory_init(address impl, address initialOwner) internal override onlyInitializing {
        _beacon = address(new UpgradeableBeacon(impl, initialOwner));
    }

    // solhint-disable-next-line no-empty-blocks
    function _deployEOFeed() internal returns (address) {
        // TODO: can be done with predictable address using create2
        return address(new BeaconProxy(_beacon, ""));
    }
}