// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { EOFeedFactoryBase } from "./EOFeedFactoryBase.sol";

abstract contract EOFeedFactoryClone is Initializable, EOFeedFactoryBase {
    address private _feedImplementation;

    function __EOFeedFactory_init(address impl, address) internal override onlyInitializing {
        _feedImplementation = impl;
    }

    function _deployEOFeed() internal override returns (address) {
        return Clones.clone(_feedImplementation);
    }
}
