// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/Script.sol";
import { EOJsonUtils } from "../../utils/EOJsonUtils.sol";
import { EOFeedManager } from "../../../src/EOFeedManager.sol";

contract SetupCoreContracts is Script {
    using stdJson for string;

    uint16[] public feedIds;
    bool[] public feedBools;
    address[] public publishers;
    bool[] public publishersBools;

    EOFeedManager public feedManager;

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

        // Set supported feedIds in FeedManager which are not set yet
        _updateSupportedFeeds(configStructured);

        // Set publishers in FeedManager which are not set yet
        _updateWhiteListedPublishers(configStructured);
    }

    function _updateSupportedFeeds(EOJsonUtils.Config memory _configData) internal {
        uint16 feedId;

        for (uint256 i = 0; i < _configData.supportedFeedIds.length; i++) {
            feedId = uint16(_configData.supportedFeedIds[i]);
            if (!feedManager.isSupportedFeed(feedId)) {
                feedIds.push(feedId);
                feedBools.push(true);
            }
        }
        if (feedIds.length > 0) {
            feedManager.setSupportedFeeds(feedIds, feedBools);
        }
    }

    function _updateWhiteListedPublishers(EOJsonUtils.Config memory _configData) internal {
        for (uint256 i = 0; i < _configData.publishers.length; i++) {
            if (!feedManager.isWhitelistedPublisher(_configData.publishers[i])) {
                publishers.push(_configData.publishers[i]);
                publishersBools.push(true);
            }
        }
        if (publishers.length > 0) {
            feedManager.whitelistPublishers(publishers, publishersBools);
        }
    }
}
