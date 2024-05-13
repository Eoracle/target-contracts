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
        vm.startBroadcast();
        feedImplementation = address(new EOFeed());

        EOJsonUtils.writeConfig(EOJsonUtils.addressToString(feedImplementation), ".feedImplementation");

        string memory outputConfig = EOJsonUtils.getOutputConfig();
        address feedRegistry = outputConfig.readAddress(".feedRegistry");

        string memory config = EOJsonUtils.getConfig();
        address targetContractsOwner = config.readAddress(".targetContractsOwner");
        address proxyAdminOwner = config.readAddress(".proxyAdminOwner");

        bytes memory initData = abi.encodeCall(
            EOFeedRegistryAdapterBase.initialize, (feedRegistry, feedImplementation, targetContractsOwner)
        );
        adapterProxy = Upgrades.deployTransparentProxy("EOFeedRegistryAdapter.sol", proxyAdminOwner, initData);

        EOJsonUtils.writeConfig(EOJsonUtils.addressToString(adapterProxy), ".feedRegistryAdapter");
        address implementationAddress = Upgrades.getImplementationAddress(adapterProxy);
        EOJsonUtils.writeConfig(
            EOJsonUtils.addressToString(implementationAddress), ".feedRegistryAdapterImplementation"
        );
    }
}
