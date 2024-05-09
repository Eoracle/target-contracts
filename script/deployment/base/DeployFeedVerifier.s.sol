// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { Script } from "forge-std/Script.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { EOFeedVerifier } from "src/EOFeedVerifier.sol";
import { ICheckpointManager } from "src/interfaces/ICheckpointManager.sol";

abstract contract FeedVerifierDeployer is Script {
    function deployFeedVerifier(
        address proxyAdmin,
        ICheckpointManager checkpointManager,
        address owner
    )
        internal
        returns (address proxyAddr)
    {
        bytes memory initData = abi.encodeCall(EOFeedVerifier.initialize, (checkpointManager, owner));

        proxyAddr = Upgrades.deployTransparentProxy("EOFeedVerifier.sol", proxyAdmin, initData);
    }
}

contract DeployFeedVerifier is FeedVerifierDeployer {
    function run(
        address proxyAdmin,
        ICheckpointManager checkpointManager,
        address owner
    )
        external
        returns (address proxyAddr)
    {
        return deployFeedVerifier(proxyAdmin, checkpointManager, owner);
    }
}
