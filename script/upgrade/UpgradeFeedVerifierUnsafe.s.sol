// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { Script, stdJson } from "forge-std/Script.sol";
import { EOJsonUtils } from "script/utils/EOJsonUtils.sol";
import { UpgradeableProxyUtils } from "../utils/UpgradeableProxyUtils.sol";

contract UpgradeFeedVerifierUnsafe is Script {
    using stdJson for string;

    function run() external {
        string memory config = EOJsonUtils.initOutputConfig();
        address feedVerifierProxyAddress = config.readAddress(".feedVerifier");

        vm.startBroadcast();
        UpgradeableProxyUtils.upgradeProxy(feedVerifierProxyAddress, "EOFeedVerifier.sol", "");
        vm.stopBroadcast();

        string memory outputConfigJson = EOJsonUtils.OUTPUT_CONFIG.serialize(
            "feedVerifierImplementation", UpgradeableProxyUtils.getImplementationAddress(feedVerifierProxyAddress)
        );
        EOJsonUtils.writeConfig(outputConfigJson);
    }
}
