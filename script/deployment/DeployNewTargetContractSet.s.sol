// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { console } from "forge-std/Test.sol";

import { stdJson } from "forge-std/Script.sol";
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
import { EOJsonUtils } from "script/utils/EOJsonUtils.sol";
import { EOFeedRegistry } from "../../src/EOFeedRegistry.sol";

// Deployment command: FOUNDRY_PROFILE="deployment" forge script script/deployment/DeployNewTargetContractSet.s.sol
// --rpc-url $RPC_URL --private-key $PRIVATE_KEY -vvv --slow --verify --broadcast
contract DeployNewTargetContractSet is CheckpointManagerDeployer, FeedVerifierDeployer, FeedRegistryDeployer {
    using stdJson for string;

    function run()
        external
        returns (
            address bls,
            address bn256G2,
            address checkpointManagerProxy,
            address feedVerifierProxy,
            address feedRegistryProxy
        )
    {
        string memory config = EOJsonUtils.getConfig();

        uint256 targetChainId = config.readUint(".targetChainId");
        uint256 currentChainId = block.chainid;
        require(targetChainId == currentChainId, "Wrong chain id for this config.");

        vm.startBroadcast();

        address proxyAdminOwner = config.readAddress(".proxyAdminOwner");

        bn256G2 = address(new BN256G2());
        string memory addressString = Strings.toHexString(uint256(uint160(bn256G2)), 20);
        EOJsonUtils.writeConfig(addressString, ".bn256G2");

        bls = address(new BLS());
        addressString = Strings.toHexString(uint256(uint160(bls)), 20);
        EOJsonUtils.writeConfig(addressString, ".bls");

        uint256 childChainId = config.readUint(".childChainId");
        address targetContractsOwner = config.readAddress(".targetContractsOwner");

        checkpointManagerProxy =
            deployCheckpointManager(proxyAdminOwner, IBLS(bls), IBN256G2(bn256G2), childChainId, targetContractsOwner);
        addressString = Strings.toHexString(uint256(uint160(checkpointManagerProxy)), 20);
        EOJsonUtils.writeConfig(addressString, ".checkpointManager");

        feedVerifierProxy =
            deployFeedVerifier(proxyAdminOwner, ICheckpointManager(checkpointManagerProxy), targetContractsOwner);
        addressString = Strings.toHexString(uint256(uint160(feedVerifierProxy)), 20);
        EOJsonUtils.writeConfig(addressString, ".feedVerifier");

        feedRegistryProxy =
            deployFeedRegistry(proxyAdminOwner, IEOFeedVerifier(feedVerifierProxy), targetContractsOwner);
        addressString = Strings.toHexString(uint256(uint160(feedRegistryProxy)), 20);
        EOJsonUtils.writeConfig(addressString, ".feedRegistry");

        vm.stopBroadcast();
        console.log("====", EOFeedRegistry(feedRegistryProxy).owner());
    }
}
