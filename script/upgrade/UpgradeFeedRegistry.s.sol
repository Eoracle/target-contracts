// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/Script.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { EOJsonUtils } from "test/utils/EOJsonUtils.sol";

contract UpgradeFeedRegistry is Script {
    using stdJson for string;

    function run() external {
        string memory config = EOJsonUtils.getConfig("targetContractAddresses.json");
        address proxyAddress = config.readAddress(".feedRegistry");
        Upgrades.upgradeProxy(proxyAddress, "EOFeedRegistryV2.sol", "");
    }
}
