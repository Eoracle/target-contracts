// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IEOFeedRegistry } from "../../src/interfaces/IEOFeedRegistry.sol";
import { IEOFeedVerifier } from "../../src/interfaces/IEOFeedVerifier.sol";
import { ICheckpointManager } from "../../src/interfaces/ICheckpointManager.sol";

import { IntegrationBaseTests } from "./IntegrationBase.t.sol";

// solhint-disable max-states-count
contract IntegrationMultipleLeavesSingleCheckpointTests is IntegrationBaseTests {
    /**
     * @notice update first symbol
     */
    function test_updatePriceFeed() public {
        vm.prank(publisher);
        registry.updatePriceFeed(input[0], checkpointData[0]);
        IEOFeedRegistry.PriceFeed memory feed = registry.getLatestPriceFeed(symbols[0]);
        assertEq(feed.value, rates[0]);
    }

    /**
     * @notice update second symbol
     */
    function test_updatePriceFeed2() public {
        vm.prank(publisher);
        registry.updatePriceFeed(input[1], checkpointData[0]);
        IEOFeedRegistry.PriceFeed memory feed = registry.getLatestPriceFeed(symbols[1]);
        assertEq(feed.value, rates[1]);
    }

    /**
     * @notice update first symbol and then second symbol
     */
    function test_updatePriceFeed_SeparateCalls() public {
        test_updatePriceFeed();
        test_updatePriceFeed2();
    }

    /**
     * @notice update first symbol and then second symbol
     */
    function test_updatePriceFeed_SeparateCallsReverse() public {
        test_updatePriceFeed2();
        test_updatePriceFeed();
    }

    /**
     * @notice update first and second symbol symultaneously
     */
    function test_updatePriceFeeds() public {
        vm.prank(publisher);
        registry.updatePriceFeeds(input, checkpointData[0]);
        IEOFeedRegistry.PriceFeed memory feed = registry.getLatestPriceFeed(symbols[0]);
        assertEq(feed.value, rates[0]);
        feed = registry.getLatestPriceFeed(symbols[1]);
        assertEq(feed.value, rates[1]);
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
        bytes[] memory bitmaps;
        uint256[2][] memory aggMessagePoints;

        ICheckpointManager.Validator[] memory validatorSetTmp;

        (validatorSetSize, validatorSetTmp, aggMessagePoints, hashes, bitmaps, unhashedLeaves, proves,) = abi.decode(
            out,
            (
                uint256,
                ICheckpointManager.Validator[],
                uint256[2][],
                bytes32[],
                bytes[],
                bytes[],
                bytes32[][],
                bytes32[][]
            )
        );

        for (uint256 i = 0; i < validatorSetSize; i++) {
            validatorSet.push(validatorSetTmp[i]);
        }

        for (uint256 i = 0; i < _symbolData.length; i++) {
            input.push(
                IEOFeedVerifier.LeafInput({
                    unhashedLeaf: unhashedLeaves[i],
                    leafIndex: i,
                    blockNumber: 1,
                    proof: proves[i]
                })
            );

            // solhint-disable-next-line func-named-parameters
        }
        checkpointData.push(
            abi.encode(
                aggMessagePoints[0], // signature
                bitmaps[0], // bitmap
                1, // epochNumber
                1,
                hashes[1], // blockHash
                0, // blockRound
                hashes[2], // currentValidatorSetHash
                hashes[0]
            )
        );
    }

    function _seedSymbolData() internal override {
        symbols = [1, 2];
        rates = [100, 101];
        timestamps = [9_999_999_999, 9_999_999_999];

        for (uint256 i = 0; i < symbols.length; i++) {
            symbolData.push(abi.encode(symbols[i], rates[i], timestamps[i]));
        }
    }
}
