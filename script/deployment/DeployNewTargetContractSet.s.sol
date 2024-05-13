// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { stdJson } from "forge-std/Script.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
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

        uint256 childChainId = config.readUint(".childChainId");
        require(childChainId == VM.envUint("CHILD_CHAIN_ID"), "Wrong CHILD_CHAIN_ID for this config.");

        vm.startBroadcast();

        address proxyAdminOwner = config.readAddress(".proxyAdminOwner");

        bn256G2 = address(new BN256G2());
        EOJsonUtils.writeConfig(EOJsonUtils.addressToString(bn256G2), ".bn256G2");

        bls = address(new BLS());
        EOJsonUtils.writeConfig(EOJsonUtils.addressToString(bls), ".bls");

        uint256 childChainId = config.readUint(".childChainId");
        address targetContractsOwner = config.readAddress(".targetContractsOwner");

        /*//////////////////////////////////////////////////////////////////////////
                                        TargetCheckpointManager
        //////////////////////////////////////////////////////////////////////////*/
        checkpointManagerProxy =
            deployCheckpointManager(proxyAdminOwner, IBLS(bls), IBN256G2(bn256G2), childChainId, targetContractsOwner);
        EOJsonUtils.writeConfig(EOJsonUtils.addressToString(checkpointManagerProxy), ".checkpointManager");

        address implementationAddress = Upgrades.getImplementationAddress(checkpointManagerProxy);
        EOJsonUtils.writeConfig(EOJsonUtils.addressToString(implementationAddress), ".checkpointManagerImplementation");

        /*//////////////////////////////////////////////////////////////////////////
                                        EOFeedVerifier
        //////////////////////////////////////////////////////////////////////////*/
        feedVerifierProxy =
            deployFeedVerifier(proxyAdminOwner, ICheckpointManager(checkpointManagerProxy), targetContractsOwner);
        EOJsonUtils.writeConfig(EOJsonUtils.addressToString(feedVerifierProxy), ".feedVerifier");

        implementationAddress = Upgrades.getImplementationAddress(feedVerifierProxy);
        EOJsonUtils.writeConfig(EOJsonUtils.addressToString(implementationAddress), ".feedVerifierImplementation");

        /*//////////////////////////////////////////////////////////////////////////
                                        EOFeedRegistry
        //////////////////////////////////////////////////////////////////////////*/
        feedRegistryProxy =
            deployFeedRegistry(proxyAdminOwner, IEOFeedVerifier(feedVerifierProxy), targetContractsOwner);
        EOJsonUtils.writeConfig(EOJsonUtils.addressToString(feedRegistryProxy), ".feedRegistry");

        implementationAddress = Upgrades.getImplementationAddress(feedRegistryProxy);
        EOJsonUtils.writeConfig(EOJsonUtils.addressToString(implementationAddress), ".feedRegistryImplementation");

        vm.stopBroadcast();
    }
}
