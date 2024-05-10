// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { Script } from "forge-std/Script.sol";
import { EoracleConsumerExampleFeed } from "src/examples/EoracleConsumerExampleFeed.sol";
import { EOJsonUtils } from "script/utils/EOJsonUtils.sol";
import { stdJson } from "forge-std/Script.sol";

contract DeployConsumerExampleFeed is Script {
    using stdJson for string;

    address public constant FEED = 0x193198556d1DbF455Aa063050eC1Cb039E8acECf; // BTC/USD feed

    function run() external returns (address consumer) {
        vm.startBroadcast();

        string memory outputConfig = EOJsonUtils.getOutputConfig();
        string memory outputConfigJsonKey = "outputConfigJsonKey";
        outputConfigJsonKey.serialize(outputConfig);

        consumer = address(new EoracleConsumerExampleFeed(FEED));
        // string memory addressString = Strings.toHexString(uint256(uint160(consumer)), 20);

        string memory outputConfigJson = outputConfigJsonKey.serialize("consumerExampleFeed", consumer);
        EOJsonUtils.writeConfig(outputConfigJson);

        // EOJsonUtils.writeConfig(addressString, ".consumerExampleFeed");

        vm.stopBroadcast();
    }
}
