// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import { Script } from "forge-std/Script.sol";
import { EoracleConsumerExampleFeedManager } from "src/examples/EoracleConsumerExampleFeedManager.sol";
import { EOJsonUtils } from "script/utils/EOJsonUtils.sol";
import { stdJson } from "forge-std/Script.sol";

contract DeployConsumerExampleFeedManager is Script {
    using stdJson for string;

    function run() external returns (address consumer) {
        vm.startBroadcast();
        string memory outputConfig = EOJsonUtils.initOutputConfig();

        address feedManager = outputConfig.readAddress(".feedManager");
        consumer = address(new EoracleConsumerExampleFeedManager(feedManager));

        string memory outputConfigJson = EOJsonUtils.OUTPUT_CONFIG.serialize("consumerExampleFeedManager", consumer);
        EOJsonUtils.writeConfig(outputConfigJson);

        vm.stopBroadcast();
    }
}
