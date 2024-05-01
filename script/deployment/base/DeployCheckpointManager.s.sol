// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import { Script } from "forge-std/Script.sol";

import { TargetCheckpointManager } from "src/TargetCheckpointManager.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { IBLS } from "src/interfaces/IBLS.sol";
import { IBN256G2 } from "src/interfaces/IBN256G2.sol";

abstract contract CheckpointManagerDeployer is Script {
    function deployCheckpointManager(
        address proxyAdmin,
        IBLS newBls,
        IBN256G2 newBn256G2,
        uint256 chainId,
        address owner
    )
        internal
        returns (address proxyAddr)
    {
        bytes memory initData = abi.encodeCall(TargetCheckpointManager.initialize, (newBls, newBn256G2, chainId, owner));

        proxyAddr = Upgrades.deployTransparentProxy("TargetCheckpointManager.sol", proxyAdmin, initData);
    }
}

contract DeployCheckpointManager is CheckpointManagerDeployer {
    function run(
        address proxyAdmin,
        IBLS newBls,
        IBN256G2 newBn256G2,
        uint256 chainId,
        address owner
    )
        external
        returns (address proxyAddr)
    {
        return deployCheckpointManager(proxyAdmin, newBls, newBn256G2, chainId, owner);
    }
}