// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { Script } from "forge-std/Script.sol";
import { EoracleConsumerExampleFeedRegistry } from "src/examples/EoracleConsumerExampleFeedRegistry.sol";
import { EOJsonUtils } from "script/utils/EOJsonUtils.sol";
import { stdJson } from "forge-std/Script.sol";

contract DeployConsumerExampleFeedRegistry is Script {
    using stdJson for string;

    function run() external returns (address consumer) {
        vm.startBroadcast();
        string memory outputConfig = EOJsonUtils.initOutputConfig();

        address feedRegistry = outputConfig.readAddress(".feedRegistry");
        consumer = address(new EoracleConsumerExampleFeedRegistry(feedRegistry));

        string memory outputConfigJson = EOJsonUtils.OUTPUT_CONFIG.serialize("consumerExampleFeedRegistry", consumer);
        EOJsonUtils.writeConfig(outputConfigJson);

        vm.stopBroadcast();
    }
}
