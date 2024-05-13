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
        // string memory config = EOJsonUtils.getConfig();
        EOJsonUtils.Config memory configStructured = EOJsonUtils.getParsedConfig();

        // uint256 targetChainId = config.readUint(".targetChainId");
        // uint256 targetChainId = configStructured.targetChainId
        require(configStructured.targetChainId == block.chainid, "Wrong chain id for this config.");

        // uint256 childChainId = config.readUint(".childChainId");
        require(configStructured.childChainId == vm.envUint("CHILD_CHAIN_ID"), "Wrong CHILD_CHAIN_ID for this config.");

        vm.startBroadcast();

        EOJsonUtils.initOutputConfig();

        bn256G2 = address(new BN256G2());
        EOJsonUtils.OUTPUT_CONFIG.serialize("bn256G2", bn256G2);

        bls = address(new BLS());
        EOJsonUtils.OUTPUT_CONFIG.serialize("bls", bls);

        /*//////////////////////////////////////////////////////////////////////////
                                        TargetCheckpointManager
        //////////////////////////////////////////////////////////////////////////*/
        checkpointManagerProxy = deployCheckpointManager(
            configStructured.proxyAdminOwner,
            IBLS(bls),
            IBN256G2(bn256G2),
            configStructured.childChainId,
            configStructured.targetContractsOwner
        );
        EOJsonUtils.OUTPUT_CONFIG.serialize("checkpointManager", checkpointManagerProxy);

        address implementationAddress = Upgrades.getImplementationAddress(checkpointManagerProxy);
        EOJsonUtils.OUTPUT_CONFIG.serialize("checkpointManagerImplementation", implementationAddress);

        /*//////////////////////////////////////////////////////////////////////////
                                        EOFeedVerifier
        //////////////////////////////////////////////////////////////////////////*/
        feedVerifierProxy = deployFeedVerifier(
            configStructured.proxyAdminOwner,
            ICheckpointManager(checkpointManagerProxy),
            configStructured.targetContractsOwner
        );
        EOJsonUtils.OUTPUT_CONFIG.serialize("feedVerifier", feedVerifierProxy);

        implementationAddress = Upgrades.getImplementationAddress(feedVerifierProxy);
        EOJsonUtils.OUTPUT_CONFIG.serialize("feedVerifierImplementation", implementationAddress);

        /*//////////////////////////////////////////////////////////////////////////
                                        EOFeedRegistry
        //////////////////////////////////////////////////////////////////////////*/
        feedRegistryProxy = deployFeedRegistry(
            configStructured.proxyAdminOwner, IEOFeedVerifier(feedVerifierProxy), configStructured.targetContractsOwner
        );
        EOJsonUtils.OUTPUT_CONFIG.serialize("feedRegistry", feedRegistryProxy);

        implementationAddress = Upgrades.getImplementationAddress(feedRegistryProxy);
        string memory outputConfigJson =
            EOJsonUtils.OUTPUT_CONFIG.serialize("feedRegistryImplementation", implementationAddress);
        EOJsonUtils.writeConfig(outputConfigJson);

        vm.stopBroadcast();
    }
}
