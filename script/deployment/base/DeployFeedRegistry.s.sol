// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import { Script } from "forge-std/Script.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { EOFeedRegistry } from "src/EOFeedRegistry.sol";
import { IEOFeedVerifier } from "src/interfaces/IEOFeedVerifier.sol";

abstract contract FeedRegistryDeployer is Script {
    function deployFeedRegistry(
        address proxyAdmin,
        IEOFeedVerifier feedVerifier,
        address owner
    )
        internal
        returns (address proxyAddr)
    {
        bytes memory initData = abi.encodeCall(EOFeedRegistry.initialize, (feedVerifier, owner));

        proxyAddr = Upgrades.deployTransparentProxy("EOFeedRegistry.sol", proxyAdmin, initData);
    }
}

contract DeployFeedRegistry is FeedRegistryDeployer {
    function run(
        address proxyAdmin,
        IEOFeedVerifier feedVerifier,
        address owner
    )
        external
        returns (address proxyAddr)
    {
        return deployFeedRegistry(proxyAdmin, feedVerifier, owner);
    }
}
