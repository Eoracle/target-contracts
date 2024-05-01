// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { EOFeedFactoryBase } from "./EOFeedFactoryBase.sol";

abstract contract EOFeedFactoryBeacon is Initializable, EOFeedFactoryBase {
    address private _beacon;

    /**
     * @dev Returns the address of the beacon.
     */
    function getBeacon() external view returns (address) {
        return _beacon;
    }

    /**
     * @dev Initializes the factory with the feed implementation.
     */
    function __EOFeedFactory_init(address impl, address initialOwner) internal override onlyInitializing {
        _beacon = address(new UpgradeableBeacon(impl, initialOwner));
    }

    /**
     * @dev Deploys a new feed instance via Beacon proxy.
     */
    function _deployEOFeed() internal override returns (address) {
        // TODO: can be done with predictable address using create2
        return address(new BeaconProxy(_beacon, ""));
    }
}
