// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/Script.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract UpgradeCheckpointManager is Script {
    using stdJson for string;

    function run() external {
        string memory config = vm.readFile("script/config/targetContractAddresses.json");
        address proxyAddress = config.readAddress(".checkpointManager");
        Upgrades.upgradeProxy(proxyAddress, "TargetCheckpointManagerV2.sol", "");
    }
}
