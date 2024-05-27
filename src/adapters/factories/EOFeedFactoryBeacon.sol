// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

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
     * @dev Initializes the factory with the feedAdapter implementation.
     */
    function __EOFeedFactory_init(address impl, address initialOwner) internal override onlyInitializing {
        _beacon = address(new UpgradeableBeacon(impl, initialOwner));
    }

    /**
     * @dev Deploys a new feedAdapter instance via Beacon proxy.
     */
    function _deployEOFeedAdapter() internal override returns (address) {
        return address(new BeaconProxy(_beacon, ""));
    }
}
