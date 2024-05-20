// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IEOFeedRegistry } from "../../src/interfaces/IEOFeedRegistry.sol";
import { IEOFeedVerifier } from "../../src/interfaces/IEOFeedVerifier.sol";
import { IntegrationBaseTests } from "./IntegrationBase.t.sol";
import { EOJsonUtils } from "../..//script/utils/EOJsonUtils.sol";
import { InvalidProof } from "../../src/interfaces/Errors.sol";

// solhint-disable max-states-count
contract IntegrationMultipleLeavesSingleCheckpointTests is IntegrationBaseTests {
    function test_updatePriceFeed() public {
        vm.prank(publisher);
        feedRegistry.updatePriceFeed(input[0], checkpoints[0], signatures[0], bitmaps[0]);
        IEOFeedRegistry.PriceFeed memory feed = feedRegistry.getLatestPriceFeed(symbols[0]);
        assertEq(feed.value, rates[0]);
        assertEq(feedRegistryAdapter.getFeedByPairSymbol(symbols[0]).latestAnswer(), int256(rates[0]));
    }

    /**
     * @notice update first symbol and then second symbol
     */
    function test_updatePriceFeed_SeparateCalls() public {
        for (uint256 i = 0; i < symbols.length; i++) {
            vm.prank(publisher);
            feedRegistry.updatePriceFeed(input[i], checkpoints[0], signatures[0], bitmaps[0]);
            IEOFeedRegistry.PriceFeed memory feed = feedRegistry.getLatestPriceFeed(symbols[i]);
            assertEq(feed.value, rates[i]);
            assertEq(feedRegistryAdapter.getFeedByPairSymbol(symbols[i]).latestAnswer(), int256(rates[i]));
        }
    }

    /**
     * @notice update first symbol and then second symbol
     */
    function test_updatePriceFeed_SeparateCallsReverse() public {
        for (uint256 i = symbols.length; i > 0;) {
            i--;
            vm.prank(publisher);
            feedRegistry.updatePriceFeed(input[i], checkpoints[0], signatures[0], bitmaps[0]);
            IEOFeedRegistry.PriceFeed memory feed = feedRegistry.getLatestPriceFeed(symbols[i]);
            assertEq(feed.value, rates[i]);
            assertEq(feedRegistryAdapter.getFeedByPairSymbol(symbols[i]).latestAnswer(), int256(rates[i]));
        }
    }

    /**
     * @notice update symbol in the same block
     */
    function test_updatePriceFeed_SameBlock() public {
        vm.startPrank(publisher);
        // it should verify signature during the first call
        vm.expectCall(
            address(feedVerifier),
            abi.encodeWithSelector(feedVerifier.verifySignature.selector, checkpoints[0], signatures[0], bitmaps[0])
        );
        feedRegistry.updatePriceFeed(input[0], checkpoints[0], signatures[0], bitmaps[0]);
        IEOFeedRegistry.PriceFeed memory feed = feedRegistry.getLatestPriceFeed(symbols[0]);
        assertEq(feed.value, rates[0]);

        // it should not verify signature during the second call in the same block
        uint256[2] memory emptySignature;
        feedRegistry.updatePriceFeed(input[1], checkpoints[0], emptySignature, bitmaps[0]);
        feed = feedRegistry.getLatestPriceFeed(symbols[1]);
        assertEq(feed.value, rates[1]);
        vm.stopPrank();
    }

    /**
     * @notice should not allow to update feed with data not related to merkle root
     */
    function test_RevertWhen_updatePriceFeed_UnsignedData(bytes memory data) public {
        vm.assume(keccak256(input[0].unhashedLeaf) != keccak256(data));
        input[0].unhashedLeaf = data;
        vm.startPrank(publisher);
        vm.expectRevert(InvalidProof.selector);
        feedRegistry.updatePriceFeed(input[0], checkpoints[0], signatures[0], bitmaps[0]);
        vm.stopPrank();
    }

    /**
     * @notice update first and second symbol symultaneously
     */
    function test_updatePriceFeeds() public {
        vm.prank(publisher);
        feedRegistry.updatePriceFeeds(input, checkpoints[0], signatures[0], bitmaps[0]);
        IEOFeedRegistry.PriceFeed memory feed;
        for (uint256 i = 0; i < symbols.length; i++) {
            feed = feedRegistry.getLatestPriceFeed(symbols[i]);
            assertEq(feed.value, rates[i]);
            assertEq(feedRegistryAdapter.getFeedByPairSymbol(symbols[i]).latestAnswer(), int256(rates[i]));
        }
    }

    function _generatePayload(bytes[] memory _symbolData) internal override {
        require(_symbolData.length > 0, "SYMBOLDATA_EMPTY");
        uint256 len = 5 + _symbolData.length;
        string[] memory cmd = new string[](len);
        cmd[0] = "npx";
        cmd[1] = "ts-node";
        cmd[2] = "test/utils/ts/generateMsgProofRates.ts";
        cmd[3] = vm.toString(abi.encode(DOMAIN));
        cmd[4] = vm.toString(abi.encode(VALIDATOR_SET_SIZE));
        for (uint256 i = 0; i < _symbolData.length; i++) {
            cmd[5 + i] = vm.toString(_symbolData[i]);
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

        for (uint256 i = 0; i < _symbolData.length; i++) {
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

    function _seedSymbolData(EOJsonUtils.Config memory configStructured) internal override {
        for (uint256 i = 0; i < configStructured.supportedSymbols.length; i++) {
            symbols.push(uint16(configStructured.supportedSymbols[i]));
            rates.push(100 + configStructured.supportedSymbols[i]);
            timestamps.push(9_999_999_999);
            symbolData.push(abi.encode(symbols[i], rates[i], timestamps[i]));
        }
    }
}
