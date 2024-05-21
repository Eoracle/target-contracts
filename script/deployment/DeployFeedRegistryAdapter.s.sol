// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/Script.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { EOFeedAdapter } from "src/adapters/EOFeedAdapter.sol";
import { EOFeedRegistryAdapterBase } from "src/adapters/EOFeedRegistryAdapterBase.sol";
import { EOJsonUtils } from "script/utils/EOJsonUtils.sol";

contract DeployFeedRegistryAdapter is Script {
    using stdJson for string;

    function run() external returns (address feedAdapterImplementation, address adapterProxy) {
        string memory outputConfig = EOJsonUtils.initOutputConfig();

        vm.startBroadcast();
        feedAdapterImplementation = address(new EOFeedAdapter());
        EOJsonUtils.OUTPUT_CONFIG.serialize("feedAdapterImplementation", feedAdapterImplementation);

        address feedManager = outputConfig.readAddress(".feedManager");

        EOJsonUtils.Config memory configStructured = EOJsonUtils.getParsedConfig();

        bytes memory initData = abi.encodeCall(
            EOFeedRegistryAdapterBase.initialize,
            (feedManager, feedAdapterImplementation, configStructured.targetContractsOwner)
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
