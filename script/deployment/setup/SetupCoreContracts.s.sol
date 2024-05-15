// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/Script.sol";
import { EOJsonUtils } from "../../utils/EOJsonUtils.sol";
import { EOFeedRegistry } from "../../../src/EOFeedRegistry.sol";

contract SetupCoreContracts is Script {
    using stdJson for string;

    uint16[] public symbols;
    bool[] public symbolsBools;
    address[] public publishers;
    bool[] public publishersBools;

    EOFeedRegistry public feedRegistry;

    function run() external {
        run(vm.addr(vm.envUint("PRIVATE_KEY")));
    }

    function run(address broadcastFrom) public {
        EOJsonUtils.Config memory configStructured = EOJsonUtils.getParsedConfig();

        string memory outputConfig = EOJsonUtils.initOutputConfig();

        feedRegistry = EOFeedRegistry(outputConfig.readAddress(".feedRegistry"));

        vm.startBroadcast(broadcastFrom);

        // Set supported symbols in FeedRegistry which are not set yet
        _updateSupportedSymbols(configStructured);

        // Set publishers in FeedRegistry which are not set yet
        _updateWhiteListedPublishers(configStructured);

        vm.stopBroadcast();
    }

    function _updateSupportedSymbols(EOJsonUtils.Config memory _configData) internal {
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

    function _updateWhiteListedPublishers(EOJsonUtils.Config memory _configData) internal {
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
