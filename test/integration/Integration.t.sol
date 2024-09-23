// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IEOFeedManager } from "../../src/interfaces/IEOFeedManager.sol";
import { IntegrationBaseTests } from "./IntegrationBase.t.sol";
import { InvalidProof } from "../../src/interfaces/Errors.sol";

// solhint-disable max-states-count
contract IntegrationMultipleLeavesSingleCheckpointTests is IntegrationBaseTests {
    function test_updatePriceFeed() public {
        vm.prank(_publisher);
        _feedManager.updatePriceFeed(input[0], vParams[0]);
        (uint16 feedId, uint256 rate,) = abi.decode(input[0].unhashedLeaf, (uint16, uint256, uint256));
        IEOFeedManager.PriceFeed memory feedAdapter = _feedManager.getLatestPriceFeed(feedId);
        assertEq(feedAdapter.value, rate);
        assertEq(_feedRegistryAdapter.getFeedById(feedId).latestAnswer(), int256(rate));
    }

    /**
     * @notice update price for first feed and then second feed
     */
    function test_updatePriceFeed_SeparateCalls() public {
        for (uint256 i = 0; i < input.length; i++) {
            vm.prank(_publisher);
            _feedManager.updatePriceFeed(input[i], vParams[0]);
            (uint16 feedId, uint256 rate,) = abi.decode(input[i].unhashedLeaf, (uint16, uint256, uint256));
            IEOFeedManager.PriceFeed memory feedAdapter = _feedManager.getLatestPriceFeed(feedId);
            assertEq(feedAdapter.value, rate);
            assertEq(_feedRegistryAdapter.getFeedById(feedId).latestAnswer(), int256(rate));
        }
    }

    /**
     * @notice update price feeds in reverse order
     */
    function test_updatePriceFeed_SeparateCallsReverse() public {
        for (uint256 i = input.length; i > 0;) {
            i--;
            vm.prank(_publisher);
            _feedManager.updatePriceFeed(input[i], vParams[0]);
            (uint16 feedId, uint256 rate,) = abi.decode(input[i].unhashedLeaf, (uint16, uint256, uint256));

            IEOFeedManager.PriceFeed memory feedAdapter = _feedManager.getLatestPriceFeed(feedId);
            assertEq(feedAdapter.value, rate);
            assertEq(_feedRegistryAdapter.getFeedById(feedId).latestAnswer(), int256(rate));
        }
    }

    /**
     * @notice update symbol in the same block
     */
    function test_updatePriceFeed_SameBlock() public {
        vm.startPrank(_publisher);
        // it should verify signature during the first call
        _feedManager.updatePriceFeed(input[0], vParams[0]);
        (uint16 feedId, uint256 rate,) = abi.decode(input[0].unhashedLeaf, (uint16, uint256, uint256));
        IEOFeedManager.PriceFeed memory feed = _feedManager.getLatestPriceFeed(feedId);
        assertEq(feed.value, rate);

        // it should not verify signature during the second call in the same block
        uint256[2] memory emptySignature;
        vParams[0].signature = emptySignature;
        _feedManager.updatePriceFeed(input[1], vParams[0]);
        (feedId, rate,) = abi.decode(input[1].unhashedLeaf, (uint16, uint256, uint256));
        feed = _feedManager.getLatestPriceFeed(feedId);
        assertEq(feed.value, rate);
        vm.stopPrank();
    }

    /**
     * @notice should not allow to update feed with data not related to merkle root
     */
    function testFuzz_RevertWhen_updatePriceFeed_UnvParams(bytes memory data) public {
        vm.assume(keccak256(input[0].unhashedLeaf) != keccak256(data));
        input[0].unhashedLeaf = data;
        vm.startPrank(_publisher);
        vm.expectRevert(InvalidProof.selector);
        _feedManager.updatePriceFeed(input[0], vParams[0]);
        vm.stopPrank();
    }

    /**
     * @notice update first and second price feeds simultaneously
     */
    function test_updatePriceFeeds() public {
        vm.prank(_publisher);
        _feedManager.updatePriceFeeds(input, vParams[0]);
        IEOFeedManager.PriceFeed memory feedAdapter;
        for (uint256 i = 0; i < input.length; i++) {
            (uint16 feedId, uint256 rate,) = abi.decode(input[i].unhashedLeaf, (uint16, uint256, uint256));
            feedAdapter = _feedManager.getLatestPriceFeed(feedId);
            assertEq(feedAdapter.value, rate);
            assertEq(_feedRegistryAdapter.getFeedById(feedId).latestAnswer(), int256(rate));
        }
    }
}
