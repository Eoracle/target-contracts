// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

abstract contract EOFeedFactoryBase {
    function __EOFeedFactory_init(address impl, address) internal virtual;

    function _deployEOFeedAdapter() internal virtual returns (address);
}
