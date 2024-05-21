// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IEOFeedManager } from "../../src/interfaces/IEOFeedManager.sol";
import { IEOFeedVerifier } from "../../src/interfaces/IEOFeedVerifier.sol";
import { IntegrationBaseTests } from "./IntegrationBase.t.sol";
import { EOJsonUtils } from "../..//script/utils/EOJsonUtils.sol";

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

    function _generatePayload(bytes[] memory _feedsData) internal override {
        require(_feedsData.length > 0, "FEEDSDATA_EMPTY");
        uint256 len = 5 + _feedsData.length;
        string[] memory cmd = new string[](len);
        cmd[0] = "npx";
        cmd[1] = "ts-node";
        cmd[2] = "test/utils/ts/generateMsgProofRates.ts";
        cmd[3] = vm.toString(abi.encode(DOMAIN));
        cmd[4] = vm.toString(abi.encode(VALIDATOR_SET_SIZE));
        for (uint256 i = 0; i < _feedsData.length; i++) {
            cmd[5 + i] = vm.toString(_feedsData[i]);
        }

        bytes memory out = vm.ffi(cmd);
        bytes[] memory unhashedLeaves;
        bytes32[][] memory proves;
        bytes32[] memory hashes;
        bytes[] memory _bitmaps;
        uint256[2][] memory aggMessagePoints;

        IEOFeedVerifier.Validator[] memory validatorSetTmp;

        (validatorSetSize, validatorSetTmp, aggMessagePoints, hashes, _bitmaps, unhashedLeaves, proves,) = abi.decode(
            out,
            (uint256, IEOFeedVerifier.Validator[], uint256[2][], bytes32[], bytes[], bytes[], bytes32[][], bytes32[][])
        );

        for (uint256 i = 0; i < validatorSetSize; i++) {
            validatorSet.push(validatorSetTmp[i]);
        }

        for (uint256 i = 0; i < _feedsData.length; i++) {
            input.push(IEOFeedVerifier.LeafInput({ unhashedLeaf: unhashedLeaves[i], leafIndex: i, proof: proves[i] }));

            // solhint-disable-next-line func-named-parameters
        }
        signatures.push(aggMessagePoints[0]);
        checkpoints.push(
            IEOFeedVerifier.Checkpoint({
                blockNumber: 1,
                epoch: 1,
                eventRoot: hashes[0],
                blockHash: hashes[1],
                blockRound: 0
            })
        );

        bitmaps.push(_bitmaps[0]);
    }

    function _seedfeedsData(EOJsonUtils.Config memory configStructured) internal override {
        for (uint256 i = 0; i < configStructured.supportedFeedIds.length; i++) {
            _feedIds.push(uint16(configStructured.supportedFeedIds[i]));
            _rates.push(100 + configStructured.supportedFeedIds[i]);
            _timestamps.push(9_999_999_999);
            feedsData.push(abi.encode(_feedIds[i], _rates[i], _timestamps[i]));
        }
    }
}
