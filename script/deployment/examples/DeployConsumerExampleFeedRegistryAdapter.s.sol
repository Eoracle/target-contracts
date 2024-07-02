// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { Script } from "forge-std/Script.sol";
import { EoracleConsumerExampleFeedRegistryAdapter } from "src/examples/EoracleConsumerExampleFeedRegistryAdapter.sol";
import { EOJsonUtils } from "script/utils/EOJsonUtils.sol";
import { stdJson } from "forge-std/Script.sol";

contract DeployConsumerExampleFeedRegistryAdapter is Script {
    using stdJson for string;

    function run() external returns (address consumer) {
        vm.startBroadcast();
        string memory outputConfig = EOJsonUtils.initOutputConfig();

        address feedRegistryAdapter = outputConfig.readAddress(".feedRegistryAdapter");
        consumer = address(new EoracleConsumerExampleFeedRegistryAdapter(feedRegistryAdapter));

        string memory outputConfigJson =
            EOJsonUtils.OUTPUT_CONFIG.serialize("consumerExampleFeedRegistryAdapter", consumer);
        EOJsonUtils.writeConfig(outputConfigJson);

        vm.stopBroadcast();
    }
}
