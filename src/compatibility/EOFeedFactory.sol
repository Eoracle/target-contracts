// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract EOFeedFactory is OwnableUpgradeable {
    function __EOFeedFactory_init() external initializer {
        __Ownable_init(msg.sender);
    }

    // solhint-disable-next-line no-empty-blocks
    function _cloneDeterministicEOFeed() internal { }
}
