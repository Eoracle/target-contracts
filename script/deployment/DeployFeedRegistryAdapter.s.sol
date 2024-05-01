// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/Script.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { EOFeed } from "src/adapters/EOFeed.sol";
import { EOFeedRegistryAdapterBase } from "src/adapters/EOFeedRegistryAdapterBase.sol";
import { EOJsonUtils } from "test/utils/EOJsonUtils.sol";

contract DeployFeedRegistryAdapter is Script {
    using stdJson for string;

    function run() external returns (address feedImplementation, address adapterProxy) {
        vm.startBroadcast();
        feedImplementation = address(new EOFeed());
        vm.stopBroadcast();

        string memory addressString = Strings.toHexString(uint256(uint160(feedImplementation)), 20);
        EOJsonUtils.writeConfig(addressString, "targetContractAddresses.json", ".feedImplementation");

        string memory addressesConfig = EOJsonUtils.getConfig("targetContractAddresses.json");
        address proxyAdmin = addressesConfig.readAddress(".proxyAdmin");
        address feedRegistry = addressesConfig.readAddress(".feedRegistry");

        string memory config = EOJsonUtils.getConfig("targetContractSetConfig.json");
        address targetContractsOwner = config.readAddress(".targetContractsOwner");

        bytes memory initData = abi.encodeCall(
            EOFeedRegistryAdapterBase.initialize, (feedRegistry, feedImplementation, targetContractsOwner)
        );
        adapterProxy = Upgrades.deployTransparentProxy("EOFeedRegistryAdapter.sol", proxyAdmin, initData);

        addressString = Strings.toHexString(uint256(uint160(adapterProxy)), 20);
        EOJsonUtils.writeConfig(addressString, "targetContractAddresses.json", ".feedRegistryAdapter");
    }
}