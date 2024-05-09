// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { EOFeedFactoryBase } from "./EOFeedFactoryBase.sol";

abstract contract EOFeedFactoryClone is Initializable, EOFeedFactoryBase {
    address private _feedImplementation;

    /**
     * @dev Returns the address of the feed implementation.
     */
    function getFeedImplementation() external view returns (address) {
        return _feedImplementation;
    }

    /**
     * @dev Initializes the factory with the feed implementation.
     */
    function __EOFeedFactory_init(address impl, address) internal override onlyInitializing {
        _feedImplementation = impl;
    }

    /**
     * @dev Deploys a new feed instance via Clones library.
     */
    function _deployEOFeed() internal override returns (address) {
        return Clones.clone(_feedImplementation);
    }
}
