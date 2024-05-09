// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import { console } from "forge-std/Test.sol";

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/Script.sol";
import { EOJsonUtils } from "../../utils/EOJsonUtils.sol";
import { EOFeedRegistry } from "../../../src/EOFeedRegistry.sol";
import { EOFeedRegistryAdapter } from "../../../src/adapters/EOFeedRegistryAdapter.sol";
import { IEOFeed } from "../../../src/adapters/interfaces/IEOFeed.sol";

contract SetupContracts is Script {
    using stdJson for string;

    struct OutputConfig {
        address bls;
        address bn256G2;
        address checkpointManager;
        address feedRegistry;
        address feedRegistryAdapter;
        address feedVerifier;
    }

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

    function run() external {
        string memory config = EOJsonUtils.getConfig();
        bytes memory configRaw = config.parseRaw(".");
        Config memory configData = abi.decode(configRaw, (Config));

        string memory outputConfig = EOJsonUtils.getOutputConfig();
        bytes memory outputConfigRaw = outputConfig.parseRaw(".");
        OutputConfig memory outputConfigData = abi.decode(outputConfigRaw, (OutputConfig));

        uint16[] memory symbols = new uint16[](configData.supportedSymbols.length);
        bool[] memory symbolsBools = new bool[](configData.supportedSymbols.length);
        for (uint256 i = 0; i < configData.supportedSymbols.length; i++) {
            symbols[i] = uint16(configData.supportedSymbols[i]);
            symbolsBools[i] = true;
        }
        bool[] memory publishersBools = new bool[](configData.publishers.length);
        for (uint256 i = 0; i < configData.publishers.length; i++) {
            publishersBools[i] = true;
        }
        vm.startBroadcast();

        EOFeedRegistry(outputConfigData.feedRegistry).whitelistPublishers(configData.publishers, publishersBools);
        EOFeedRegistry(outputConfigData.feedRegistry).setSupportedSymbols(symbols, symbolsBools);

        IEOFeed feed;
        for (uint256 i = 0; i < configData.supportedSymbolsData.length; i++) {
            console.log(EOFeedRegistryAdapter(outputConfigData.feedRegistryAdapter).owner());
            console.log(configData.supportedSymbolsData[i].symbolId);
            feed = EOFeedRegistryAdapter(outputConfigData.feedRegistryAdapter).deployEOFeed(
                configData.supportedSymbolsData[i].base,
                configData.supportedSymbolsData[i].quote,
                uint16(configData.supportedSymbolsData[i].symbolId),
                configData.supportedSymbolsData[i].description,
                uint8(configData.supportedSymbolsData[i].decimals),
                1
            );
            console.log("feed", address(feed));
        }
        vm.stopBroadcast();
    }
}
