// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/Script.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { EOJsonUtils } from "script/utils/EOJsonUtils.sol";

contract UpgradeFeedRegistryAdapter is Script {
    using stdJson for string;

    function run() external {
        string memory config = EOJsonUtils.getOutputConfig();
        address proxyAddress = config.readAddress(".feedRegistryAdapter");
        Upgrades.upgradeProxy(proxyAddress, "EOFeedRegistryAdapterV2.sol", "");
    }
}
