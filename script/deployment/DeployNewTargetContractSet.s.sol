// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { stdJson } from "forge-std/Script.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { FeedVerifierDeployer } from "./base/DeployFeedVerifier.s.sol";
import { FeedManagerDeployer } from "./base/DeployFeedManager.s.sol";
import { BLS } from "src/common/BLS.sol";
import { IBLS } from "src/interfaces/IBLS.sol";
import { IEOFeedVerifier } from "src/interfaces/IEOFeedVerifier.sol";
import { EOJsonUtils } from "script/utils/EOJsonUtils.sol";

// Deployment command: FOUNDRY_PROFILE="deployment" forge script script/deployment/DeployNewTargetContractSet.s.sol
// --rpc-url $RPC_URL --private-key $PRIVATE_KEY -vvv --slow --verify --broadcast
contract DeployNewTargetContractSet is FeedVerifierDeployer, FeedManagerDeployer {
    using stdJson for string;

    function run() external {
        run(vm.addr(vm.envUint("PRIVATE_KEY")));
    }

    function run(address broadcastFrom)
        public
        returns (address bls, address feedVerifierProxy, address feedManagerProxy)
    {
        EOJsonUtils.Config memory configStructured = EOJsonUtils.getParsedConfig();

        require(configStructured.targetChainId == block.chainid, "Wrong chain id for this config.");

        require(
            configStructured.eoracleChainId == vm.envUint("EORACLE_CHAIN_ID"), "Wrong EORACLE_CHAIN_ID for this config."
        );

        vm.startBroadcast(broadcastFrom);

        EOJsonUtils.initOutputConfig();

        bls = address(new BLS());
        EOJsonUtils.OUTPUT_CONFIG.serialize("bls", bls);

        /*//////////////////////////////////////////////////////////////////////////
                                        EOFeedVerifier
        //////////////////////////////////////////////////////////////////////////*/
        feedVerifierProxy = deployFeedVerifier(
            configStructured.proxyAdminOwner, broadcastFrom, IBLS(bls), configStructured.eoracleChainId
        );
        EOJsonUtils.OUTPUT_CONFIG.serialize("feedVerifier", feedVerifierProxy);

        address implementationAddress = Upgrades.getImplementationAddress(feedVerifierProxy);
        EOJsonUtils.OUTPUT_CONFIG.serialize("feedVerifierImplementation", implementationAddress);

        /*//////////////////////////////////////////////////////////////////////////
                                        EOFeedManager
        //////////////////////////////////////////////////////////////////////////*/
        feedManagerProxy = deployFeedManager(
            configStructured.proxyAdminOwner, feedVerifierProxy, configStructured.targetContractsOwner
        );

        // set feedManager in feedVerifier
        IEOFeedVerifier(feedVerifierProxy).setFeedManager(feedManagerProxy);
        // transfer ownership of feedVerifier to targetContractsOwner
        if (OwnableUpgradeable(feedVerifierProxy).owner() != configStructured.targetContractsOwner) {
            OwnableUpgradeable(feedVerifierProxy).transferOwnership(configStructured.targetContractsOwner);
        }

        vm.stopBroadcast();
        EOJsonUtils.OUTPUT_CONFIG.serialize("feedManager", feedManagerProxy);

        implementationAddress = Upgrades.getImplementationAddress(feedManagerProxy);
        string memory outputConfigJson =
            EOJsonUtils.OUTPUT_CONFIG.serialize("feedManagerImplementation", implementationAddress);
        EOJsonUtils.writeConfig(outputConfigJson);
    }
}
