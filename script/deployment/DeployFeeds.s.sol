// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/Script.sol";
import { EOJsonUtils } from "../utils/EOJsonUtils.sol";
import { EOFeedRegistry } from "../../src/EOFeedRegistry.sol";
import { EOFeedRegistryAdapter } from "../../src/adapters/EOFeedRegistryAdapter.sol";

contract DeployFeeds is Script {
    using stdJson for string;

    EOFeedRegistry public feedRegistry;
    EOFeedRegistryAdapter public feedRegistryAdapter;

    error SymbolNotSupported(uint16 symbolId);

    function run() external {
        EOJsonUtils.Config memory configStructured = EOJsonUtils.getParsedConfig();

        string memory outputConfig = EOJsonUtils.initOutputConfig();

        feedRegistry = EOFeedRegistry(outputConfig.readAddress(".feedRegistry"));
        feedRegistryAdapter = EOFeedRegistryAdapter(outputConfig.readAddress(".feedRegistryAdapter"));

        vm.startBroadcast();

        // Deploy feeds which are not deployed yet
        address feed;
        string memory feedAddressesJsonKey = "feedsJson";
        string memory feedAddressesJson;
        uint16 symbolId;

        // revert if at least one symbol is not supported
        for (uint256 i = 0; i < configStructured.supportedSymbolsData.length; i++) {
            if (!feedRegistry.isSupportedSymbol(symbolId)) {
                revert SymbolNotSupported(symbolId);
            }
        }

        for (uint256 i = 0; i < configStructured.supportedSymbolsData.length; i++) {
            symbolId = uint16(configStructured.supportedSymbolsData[i].symbolId);
            feed = address(feedRegistryAdapter.getFeedByPairSymbol(symbolId));
            if (feed == address(0)) {
                feed = address(
                    feedRegistryAdapter.deployEOFeed(
                        configStructured.supportedSymbolsData[i].base,
                        configStructured.supportedSymbolsData[i].quote,
                        symbolId,
                        configStructured.supportedSymbolsData[i].description,
                        uint8(configStructured.supportedSymbolsData[i].decimals),
                        1
                    )
                );
            }
            feedAddressesJson =
                feedAddressesJsonKey.serialize(configStructured.supportedSymbolsData[i].description, feed);
        }
        string memory outputConfigJson = EOJsonUtils.OUTPUT_CONFIG.serialize("feeds", feedAddressesJson);
        EOJsonUtils.writeConfig(outputConfigJson);

        vm.stopBroadcast();
    }
}
