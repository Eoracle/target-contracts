// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import { stdJson } from "forge-std/Script.sol";

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { CheckpointManagerDeployer } from "./DeployCheckpointManager.s.sol";
import { FeedVerifierDeployer } from "./DeployFeedVerifier.s.sol";
import { FeedRegistryDeployer } from "./DeployFeedRegistry.s.sol";

import { BN256G2 } from "src/common/BN256G2.sol";
import { BLS } from "src/common/BLS.sol";
import { IBN256G2 } from "src/interfaces/IBN256G2.sol";
import { IBLS } from "src/interfaces/IBLS.sol";
import { ICheckpointManager } from "src/interfaces/ICheckpointManager.sol";
import { IEOFeedVerifier } from "src/interfaces/IEOFeedVerifier.sol";

contract DeployNewTargetContractSet is CheckpointManagerDeployer, FeedVerifierDeployer, FeedRegistryDeployer {
    using stdJson for string;

    function run()
        external
        returns (
            address proxyAdmin,
            address checkpointManagerProxy,
            address feedVerifierProxy,
            address feedRegistryProxy
        )
    {
        string memory config = vm.readFile("script/config/targetContractSetConfig.json");

        vm.startBroadcast();

        address proxyAdminOwner = config.readAddress(".proxyAdminOwner");
        proxyAdmin = address(new ProxyAdmin(proxyAdminOwner));

        BN256G2 bn256G2 = new BN256G2();
        BLS bls = new BLS();

        vm.stopBroadcast();

        uint256 chainId = config.readUint(".chainId");
        address checkpointManagerOwner = config.readAddress(".checkpointManagerOwner");

        checkpointManagerProxy =
            deployCheckpointManager(proxyAdmin, IBLS(bls), IBN256G2(bn256G2), chainId, checkpointManagerOwner);
        string memory addressString = Strings.toHexString(uint256(uint160(checkpointManagerProxy)), 20);
        vm.writeJson(addressString, "script/config/targetContractAddresses.json", ".checkpointManager");

        address feedVerifierOwner = config.readAddress(".feedVerifierOwner");
        feedVerifierProxy =
            deployFeedVerifier(proxyAdmin, ICheckpointManager(checkpointManagerProxy), feedVerifierOwner);
        addressString = Strings.toHexString(uint256(uint160(feedVerifierProxy)), 20);
        vm.writeJson(addressString, "script/config/targetContractAddresses.json", ".feedVerifier");

        address feedRegistryOwner = config.readAddress(".feedRegistryOwner");
        feedRegistryProxy = deployFeedRegistry(proxyAdmin, IEOFeedVerifier(feedVerifierProxy), feedRegistryOwner);
        addressString = Strings.toHexString(uint256(uint160(feedRegistryProxy)), 20);
        vm.writeJson(addressString, "script/config/targetContractAddresses.json", ".feedRegistry");
    }
}
