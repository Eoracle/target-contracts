// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IEOFeedManager } from "../../src/interfaces/IEOFeedManager.sol";
import { IntegrationBaseTests } from "./IntegrationBase.t.sol";
import { EOJsonUtils } from "../..//script/utils/EOJsonUtils.sol";
import { InvalidProof } from "../../src/interfaces/Errors.sol";

// solhint-disable max-states-count
contract IntegrationMultipleLeavesSingleCheckpointTests is IntegrationBaseTests {
    function test_updatePriceFeed() public {
        vm.prank(_publisher);
        _feedManager.updatePriceFeed(input[0], checkpoints[0], signatures[0], bitmaps[0]);
        IEOFeedManager.PriceFeed memory feedAdapter = _feedManager.getLatestPriceFeed(_feedIds[0]);
        assertEq(feedAdapter.value, _rates[0]);
        assertEq(_feedRegistryAdapter.getFeedById(_feedIds[0]).latestAnswer(), int256(_rates[0]));
    }

    /**
     * @notice update price for first feed and then second feed
     */
    function test_updatePriceFeed_SeparateCalls() public {
        for (uint256 i = 0; i < _feedIds.length; i++) {
            vm.prank(_publisher);
            _feedManager.updatePriceFeed(input[i], checkpoints[0], signatures[0], bitmaps[0]);
            IEOFeedManager.PriceFeed memory feedAdapter = _feedManager.getLatestPriceFeed(_feedIds[i]);
            assertEq(feedAdapter.value, _rates[i]);
            assertEq(_feedRegistryAdapter.getFeedById(_feedIds[i]).latestAnswer(), int256(_rates[i]));
        }
    }

    /**
     * @notice update price feeds in reverse order
     */
    function test_updatePriceFeed_SeparateCallsReverse() public {
        for (uint256 i = _feedIds.length; i > 0;) {
            i--;
            vm.prank(_publisher);
            _feedManager.updatePriceFeed(input[i], checkpoints[0], signatures[0], bitmaps[0]);
            IEOFeedManager.PriceFeed memory feedAdapter = _feedManager.getLatestPriceFeed(_feedIds[i]);
            assertEq(feedAdapter.value, _rates[i]);
            assertEq(_feedRegistryAdapter.getFeedById(_feedIds[i]).latestAnswer(), int256(_rates[i]));
        }
    }

    /**
     * @notice update symbol in the same block
     */
    function test_updatePriceFeed_SameBlock() public {
        vm.startPrank(_publisher);
        // it should verify signature during the first call
        _feedManager.updatePriceFeed(input[0], checkpoints[0], signatures[0], bitmaps[0]);
        IEOFeedManager.PriceFeed memory feed = _feedManager.getLatestPriceFeed(_feedIds[0]);
        assertEq(feed.value, _rates[0]);

        // it should not verify signature during the second call in the same block
        uint256[2] memory emptySignature;
        _feedManager.updatePriceFeed(input[1], checkpoints[0], emptySignature, bitmaps[0]);
        feed = _feedManager.getLatestPriceFeed(_feedIds[1]);
        assertEq(feed.value, _rates[1]);
        vm.stopPrank();
    }

    /**
     * @notice should not allow to update feed with data not related to merkle root
     */
    function testFuzz_RevertWhen_updatePriceFeed_UnsignedData(bytes memory data) public {
        vm.assume(keccak256(input[0].unhashedLeaf) != keccak256(data));
        input[0].unhashedLeaf = data;
        vm.startPrank(_publisher);
        vm.expectRevert(InvalidProof.selector);
        _feedManager.updatePriceFeed(input[0], checkpoints[0], signatures[0], bitmaps[0]);
        vm.stopPrank();
    }

    /**
     * @notice update first and second price feeds simultaneously
     */
    function test_updatePriceFeeds() public {
        vm.prank(_publisher);
        _feedManager.updatePriceFeeds(input, checkpoints[0], signatures[0], bitmaps[0]);
        IEOFeedManager.PriceFeed memory feedAdapter;
        for (uint256 i = 0; i < _feedIds.length; i++) {
            feedAdapter = _feedManager.getLatestPriceFeed(_feedIds[i]);
            assertEq(feedAdapter.value, _rates[i]);
            assertEq(_feedRegistryAdapter.getFeedById(_feedIds[i]).latestAnswer(), int256(_rates[i]));
        }
    }
}

// solhint-disable max-states-count
contract IntegrationMultipleCheckpointsTests is IntegrationBaseTests {
    /**
     * @notice update the same price feed in different checkpoints
     */
    function test_updatePriceFeed_SameFeedsMultipleCheckpoints() public {
        vm.prank(_publisher);
        _feedManager.updatePriceFeed(input[0], checkpoints[0], signatures[0], bitmaps[0]);
        IEOFeedManager.PriceFeed memory feedAdapter = _feedManager.getLatestPriceFeed(_feedIds[0]);
        assertEq(feedAdapter.value, _rates[0]);
        assertEq(_feedRegistryAdapter.getFeedById(_feedIds[0]).latestAnswer(), int256(_rates[0]));

        vm.warp(block.timestamp + 1);

        EOJsonUtils.Config memory configStructured = EOJsonUtils.getParsedConfig();
        // create new rates
        _seedFeedsData(configStructured, uint256(99));
        // create new checkpoint
        _generatePayload(feedsData);
        _setValidatorSet(validatorSet);

        vm.prank(_publisher);
        _feedManager.updatePriceFeed(input[0], checkpoints[0], signatures[0], bitmaps[0]);
        feedAdapter = _feedManager.getLatestPriceFeed(_feedIds[0]);
        assertEq(feedAdapter.value, _rates[0]);
        assertEq(_feedRegistryAdapter.getFeedById(_feedIds[0]).latestAnswer(), int256(_rates[0]));
    }

    /**
     * @notice update different price feeds in different checkpoints
     */
    function test_updatePriceFeed_DifferentFeedsMultipleCheckpoints() public {
        vm.prank(_publisher);
        _feedManager.updatePriceFeed(input[0], checkpoints[0], signatures[0], bitmaps[0]);
        IEOFeedManager.PriceFeed memory feedAdapter1 = _feedManager.getLatestPriceFeed(_feedIds[0]);
        uint256 feed1Value = _rates[0];
        uint256 feed1BlockNumber = block.number;
        assertEq(feedAdapter1.value, feed1Value);
        assertEq(feedAdapter1.eoracleBlockNumber, feed1BlockNumber);

        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 1);

        // create new rates
        delete feedsData;
        feedsData.push(abi.encode(_feedIds[1], _rates[1], block.timestamp));
        // create new checkpoint
        _generatePayload(feedsData);
        _setValidatorSet(validatorSet);

        vm.prank(_publisher);
        _feedManager.updatePriceFeed(input[0], checkpoints[0], signatures[0], bitmaps[0]);
        IEOFeedManager.PriceFeed memory feedAdapter2 = _feedManager.getLatestPriceFeed(_feedIds[1]);
        assertEq(feedAdapter2.value, _rates[1]);
        assertEq(feedAdapter2.eoracleBlockNumber, block.number);
        // check that first feed was not updated
        assertEq(feedAdapter1.value, feed1Value);
        assertEq(feedAdapter1.eoracleBlockNumber, feed1BlockNumber);
    }

    /**
     * @notice update multiple price feeds in different checkpoints
     */
    function test_updatePriceFeeds_MultipleCheckpoints() public {
        IEOFeedManager.PriceFeed memory feedAdapter;
        vm.prank(_publisher);
        _feedManager.updatePriceFeeds(input, checkpoints[0], signatures[0], bitmaps[0]);
        for (uint256 i = 0; i < _feedIds.length; i++) {
            feedAdapter = _feedManager.getLatestPriceFeed(_feedIds[i]);
            assertEq(feedAdapter.value, _rates[i]);
        }

        vm.warp(block.timestamp + 1);

        EOJsonUtils.Config memory configStructured = EOJsonUtils.getParsedConfig();
        // create new rates
        _seedFeedsData(configStructured, uint256(99));
        // create new checkpoint
        _generatePayload(feedsData);
        _setValidatorSet(validatorSet);

        vm.prank(_publisher);
        _feedManager.updatePriceFeeds(input, checkpoints[0], signatures[0], bitmaps[0]);
        for (uint256 i = 0; i < _feedIds.length; i++) {
            feedAdapter = _feedManager.getLatestPriceFeed(_feedIds[i]);
            assertEq(feedAdapter.value, _rates[i]);
        }
    }
}
