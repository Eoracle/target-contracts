// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/Script.sol";
import { EOJsonUtils } from "../../utils/EOJsonUtils.sol";
import { EOFeedRegistry } from "../../../src/EOFeedRegistry.sol";
import { EOFeedRegistryAdapter } from "../../../src/adapters/EOFeedRegistryAdapter.sol";

contract SetupContracts is Script {
    using stdJson for string;

    struct Config {
        uint256 childChainId;
        address proxyAdminOwner;
        address[] publishers;
        uint256[] supportedSymbols;
        SymbolData[] supportedSymbolsData;
        uint256 targetChainId;
        address targetContractsOwner;
    }

    struct SymbolData {
        address base;
        uint256 decimals;
        string description;
        address quote;
        uint256 symbolId;
    }

    uint16[] public symbols;
    bool[] public symbolsBools;
    address[] public publishers;
    bool[] public publishersBools;

    EOFeedRegistry public feedRegistry;
    EOFeedRegistryAdapter public feedRegistryAdapter;

    function run() external {
        Config memory configData;
        string memory config = EOJsonUtils.getConfig();
        bytes memory configRaw = config.parseRaw(".");
        configData = abi.decode(configRaw, (Config));

        string memory outputConfig = EOJsonUtils.getOutputConfig();
        string memory outputConfigJsonKey = "outputConfigJsonKey";
        outputConfigJsonKey.serialize(outputConfig);

        feedRegistry = EOFeedRegistry(outputConfig.readAddress(".feedRegistry"));
        feedRegistryAdapter = EOFeedRegistryAdapter(outputConfig.readAddress(".feedRegistryAdapter"));

        vm.startBroadcast();

        // Set supported symbols in FeedRegistry which are not set yet
        _updateSupportedSymbols(configData);

        // Set publishers in FeedRegistry which are not set yet
        _updateWhiteListedPublishers(configData);

        // Deploy feeds which are not deployed yet
        address feed;
        string memory feedAddressesJsonKey = "feedsJson";
        string memory feedAddressesJson;

        for (uint256 i = 0; i < configData.supportedSymbolsData.length; i++) {
            feed = address(feedRegistryAdapter.getFeedByPairSymbol(uint16(configData.supportedSymbolsData[i].symbolId)));
            if (feed == address(0)) {
                feed = address(
                    feedRegistryAdapter.deployEOFeed(
                        configData.supportedSymbolsData[i].base,
                        configData.supportedSymbolsData[i].quote,
                        uint16(configData.supportedSymbolsData[i].symbolId),
                        configData.supportedSymbolsData[i].description,
                        uint8(configData.supportedSymbolsData[i].decimals),
                        1
                    )
                );
            }
            feedAddressesJson = feedAddressesJsonKey.serialize(configData.supportedSymbolsData[i].description, feed);
        }
        string memory outputConfigJson = outputConfigJsonKey.serialize("feeds", feedAddressesJson);
        EOJsonUtils.writeConfig(outputConfigJson);

        vm.stopBroadcast();
    }

    function _updateSupportedSymbols(Config memory _configData) internal {
        uint16 symbolId;

        for (uint256 i = 0; i < _configData.supportedSymbols.length; i++) {
            symbolId = uint16(_configData.supportedSymbols[i]);
            if (!feedRegistry.isSupportedSymbol(symbolId)) {
                symbols.push(symbolId);
                symbolsBools.push(true);
            }
        }
        if (symbols.length > 0) {
            feedRegistry.setSupportedSymbols(symbols, symbolsBools);
        }
    }

    function _updateWhiteListedPublishers(Config memory _configData) internal {
        for (uint256 i = 0; i < _configData.publishers.length; i++) {
            if (!feedRegistry.isWhitelistedPublisher(_configData.publishers[i])) {
                publishers.push(_configData.publishers[i]);
                publishersBools.push(true);
            }
        }
        if (publishers.length > 0) {
            feedRegistry.whitelistPublishers(publishers, publishersBools);
        }
    }
}
