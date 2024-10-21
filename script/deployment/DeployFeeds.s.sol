// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/Script.sol";
import { EOJsonUtils } from "../utils/EOJsonUtils.sol";
import { EOFeedManager } from "../../src/EOFeedManager.sol";
import { EOFeedRegistryAdapter } from "../../src/adapters/EOFeedRegistryAdapter.sol";

contract DeployFeeds is Script {
    using stdJson for string;

    EOFeedManager public feedManager;
    EOFeedRegistryAdapter public feedRegistryAdapter;

    error FeedIsNotSupported(uint16 feedId);

    function run() external {
        uint256 pk = vm.envUint("OWNER_PRIVATE_KEY");
        vm.startBroadcast(pk);
        execute();
        vm.stopBroadcast();
    }

    // for testing purposes
    function run(address broadcastFrom) public {
        vm.startBroadcast(broadcastFrom);
        execute();
        vm.stopBroadcast();
    }

    function execute() public {
        EOJsonUtils.Config memory configStructured = EOJsonUtils.getParsedConfig();

        string memory outputConfig = EOJsonUtils.initOutputConfig();

        feedManager = EOFeedManager(outputConfig.readAddress(".feedManager"));
        feedRegistryAdapter = EOFeedRegistryAdapter(outputConfig.readAddress(".feedRegistryAdapter"));

        // Deploy feeds which are not deployed yet
        address feedAdapter;
        string memory feedAddressesJsonKey = "feedsJson";
        string memory feedAddressesJson;
        uint16 feedId;
        uint256 feedsLength = configStructured.supportedFeedsData.length;

        // revert if at least one feedId is not supported.
        for (uint256 i = 0; i < feedsLength; i++) {
            feedId = uint16(configStructured.supportedFeedsData[i].feedId);
            if (!feedManager.isSupportedFeed(feedId)) {
                revert FeedIsNotSupported(feedId);
            }
        }

        for (uint256 i = 0; i < feedsLength; i++) {
            feedId = uint16(configStructured.supportedFeedsData[i].feedId);
            feedAdapter = address(feedRegistryAdapter.getFeedById(feedId));
            if (feedAdapter == address(0)) {
                feedAdapter = address(
                    feedRegistryAdapter.deployEOFeedAdapter(
                        configStructured.supportedFeedsData[i].base,
                        configStructured.supportedFeedsData[i].quote,
                        feedId,
                        configStructured.supportedFeedsData[i].description,
                        uint8(configStructured.supportedFeedsData[i].inputDecimals),
                        uint8(configStructured.supportedFeedsData[i].outputDecimals),
                        1
                    )
                );
            }
            feedAddressesJson =
                feedAddressesJsonKey.serialize(configStructured.supportedFeedsData[i].description, feedAdapter);
        }
        string memory outputConfigJson = EOJsonUtils.OUTPUT_CONFIG.serialize("feeds", feedAddressesJson);
        EOJsonUtils.writeConfig(outputConfigJson);
    }
}
