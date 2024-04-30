// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import { Script } from "forge-std/Script.sol";

import { TargetCheckpointManager } from "src/TargetCheckpointManager.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

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
        returns (address logicAddr, address proxyAddr)
    {
        bytes memory initData = abi.encodeCall(TargetCheckpointManager.initialize, (newBls, newBn256G2, chainId));

        return _deployCheckpointManager(proxyAdmin, initData, owner);
    }

    function _deployCheckpointManager(
        address proxyAdmin,
        bytes memory initData,
        address owner
    )
        private
        returns (address logicAddr, address proxyAddr)
    {
        vm.startBroadcast();

        TargetCheckpointManager checkpointManager = new TargetCheckpointManager();

        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(address(checkpointManager), proxyAdmin, initData);

        TargetCheckpointManager(proxy).transferOwnership(owner);
        vm.stopBroadcast();

        logicAddr = address(checkpointManager);
        proxyAddr = address(proxy);
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
        returns (address logicAddr, address proxyAddr)
    {
        return deployCheckpointManager(proxyAdmin, newBls, newBn256G2, chainId, owner);
    }
}
