// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import { stdJson } from "forge-std/Script.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { CheckpointManagerDeployer } from "./base/DeployCheckpointManager.s.sol";
import { FeedVerifierDeployer } from "./base/DeployFeedVerifier.s.sol";
import { FeedRegistryDeployer } from "./base/DeployFeedRegistry.s.sol";
import { BN256G2 } from "src/common/BN256G2.sol";
import { BLS } from "src/common/BLS.sol";
import { IBN256G2 } from "src/interfaces/IBN256G2.sol";
import { IBLS } from "src/interfaces/IBLS.sol";
import { ICheckpointManager } from "src/interfaces/ICheckpointManager.sol";
import { IEOFeedVerifier } from "src/interfaces/IEOFeedVerifier.sol";
import { EOJsonUtils } from "test/utils/EOJsonUtils.sol";

contract DeployNewTargetContractSet is CheckpointManagerDeployer, FeedVerifierDeployer, FeedRegistryDeployer {
    using stdJson for string;

    function run()
        external
        returns (
            address bls,
            address bn256G2,
            address proxyAdmin,
            address checkpointManagerProxy,
            address feedVerifierProxy,
            address feedRegistryProxy
        )
    {
        string memory config = EOJsonUtils.getConfig();

        vm.startBroadcast();

        address proxyAdminOwner = config.readAddress(".proxyAdminOwner");
        proxyAdmin = address(new ProxyAdmin(proxyAdminOwner));
        string memory addressString = Strings.toHexString(uint256(uint160(proxyAdmin)), 20);
        EOJsonUtils.writeConfig(addressString, ".proxyAdmin");

        bn256G2 = address(new BN256G2());
        bls = address(new BLS());

        vm.stopBroadcast();

        uint256 chainId = config.readUint(".chainId");
        address targetContractsOwner = config.readAddress(".targetContractsOwner");

        checkpointManagerProxy =
            deployCheckpointManager(proxyAdmin, IBLS(bls), IBN256G2(bn256G2), chainId, targetContractsOwner);
        addressString = Strings.toHexString(uint256(uint160(checkpointManagerProxy)), 20);
        EOJsonUtils.writeConfig(addressString, ".checkpointManager");

        feedVerifierProxy =
            deployFeedVerifier(proxyAdmin, ICheckpointManager(checkpointManagerProxy), targetContractsOwner);
        addressString = Strings.toHexString(uint256(uint160(feedVerifierProxy)), 20);
        EOJsonUtils.writeConfig(addressString, ".feedVerifier");

        feedRegistryProxy = deployFeedRegistry(proxyAdmin, IEOFeedVerifier(feedVerifierProxy), targetContractsOwner);
        addressString = Strings.toHexString(uint256(uint160(feedRegistryProxy)), 20);
        EOJsonUtils.writeConfig(addressString, ".feedRegistry");
    }
}
