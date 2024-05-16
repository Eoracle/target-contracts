// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/Script.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { EOFeed } from "src/adapters/EOFeed.sol";
import { EOFeedRegistryAdapterBase } from "src/adapters/EOFeedRegistryAdapterBase.sol";
import { EOJsonUtils } from "script/utils/EOJsonUtils.sol";

contract DeployFeedRegistryAdapter is Script {
    using stdJson for string;

    function run() external returns (address feedImplementation, address adapterProxy) {
        string memory outputConfig = EOJsonUtils.initOutputConfig();

        vm.startBroadcast();
        feedImplementation = address(new EOFeed());
        EOJsonUtils.OUTPUT_CONFIG.serialize("feedImplementation", feedImplementation);

        address feedRegistry = outputConfig.readAddress(".feedRegistry");

        EOJsonUtils.Config memory configStructured = EOJsonUtils.getParsedConfig();

        bytes memory initData = abi.encodeCall(
            EOFeedRegistryAdapterBase.initialize,
            (feedRegistry, feedImplementation, configStructured.targetContractsOwner)
        );
        adapterProxy =
            Upgrades.deployTransparentProxy("EOFeedRegistryAdapter.sol", configStructured.proxyAdminOwner, initData);
        EOJsonUtils.OUTPUT_CONFIG.serialize("feedRegistryAdapter", adapterProxy);
        address implementationAddress = Upgrades.getImplementationAddress(adapterProxy);
        string memory outputConfigJson =
            EOJsonUtils.OUTPUT_CONFIG.serialize("feedRegistryAdapterImplementation", implementationAddress);
        EOJsonUtils.writeConfig(outputConfigJson);
        vm.stopBroadcast();
    }
}
