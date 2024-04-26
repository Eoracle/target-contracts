// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { IEOFeedFactory } from "./IEOFeedFactory.sol";

abstract contract EOFeedFactoryBeacon is Initializable, IEOFeedFactory {
    address private _beacon;

    function __EOFeedFactory_init(address impl, address initialOwner) public initializer {
        _beacon = address(new UpgradeableBeacon(impl, initialOwner));
    }

    // solhint-disable-next-line no-empty-blocks
    function _deployEOFeed() internal returns (address) {
        return address(new BeaconProxy(_beacon, ""));
    }
}
