// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/Script.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { EOJsonUtils } from "script/utils/EOJsonUtils.sol";

contract UpgradeFeedRegistryAdapter is Script {
    using stdJson for string;

    function run() external {
        string memory config = EOJsonUtils.initOutputConfig();
        address proxyAddress = config.readAddress(".feedRegistryAdapter");
        vm.startBroadcast();
        Upgrades.upgradeProxy(proxyAddress, "EOFeedRegistryAdapterV2.sol", "");
        vm.stopBroadcast();
        address implementationAddress = Upgrades.getImplementationAddress(proxyAddress);
        string memory outputConfigJson =
            EOJsonUtils.OUTPUT_CONFIG.serialize("feedRegistryAdapterImplementation", implementationAddress);
        EOJsonUtils.writeConfig(outputConfigJson);
    }
}
