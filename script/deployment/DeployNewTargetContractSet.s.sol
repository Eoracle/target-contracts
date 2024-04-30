// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import { stdJson } from "forge-std/Script.sol";

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import { CheckpointManagerDeployer } from "./DeployCheckpointManager.s.sol";

import { BN256G2 } from "src/common/BN256G2.sol";
import { BLS } from "src/common/BLS.sol";
import { IBN256G2 } from "src/interfaces/IBN256G2.sol";
import { IBLS } from "src/interfaces/IBLS.sol";

contract DeployNewTargetContractSet is CheckpointManagerDeployer {
    using stdJson for string;

    function run()
        external
        returns (address proxyAdmin, address checkpointManagerLogic, address checkpointManagerProxy)
    {
        string memory config = vm.readFile("script/deployment/targetContractSetConfig.json");

        vm.startBroadcast();

        address proxyAdminOwner = config.readAddress(".proxyAdminOwner");
        ProxyAdmin _proxyAdmin = new ProxyAdmin(proxyAdminOwner);

        BN256G2 bn256G2 = new BN256G2();
        BLS bls = new BLS();

        vm.stopBroadcast();
        uint256 chainId = config.readUint(".chainId");
        address owner = config.readAddress(".CheckpointManager.owner");
        proxyAdmin = address(_proxyAdmin);

        // To be initialized manually later.
        (checkpointManagerLogic, checkpointManagerProxy) =
            deployCheckpointManager(proxyAdmin, IBLS(bls), IBN256G2(bn256G2), chainId, owner);
    }
}
