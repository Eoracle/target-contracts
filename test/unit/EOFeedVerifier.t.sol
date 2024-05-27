// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IEOFeedVerifier } from "../../src/interfaces/IEOFeedVerifier.sol";
import { IBLS } from "../../src/interfaces/IBLS.sol";
import { UninitializedFeedVerifier, InitializedFeedVerifier } from "./EOFeedVerifierBase.t.sol";
import {
    InvalidProof,
    InvalidAddress,
    VotingPowerIsZero,
    AggVotingPowerIsZero,
    InsufficientVotingPower,
    CallerIsNotFeedManager,
    InvalidEventRoot
} from "../../src/interfaces/Errors.sol";

contract EOFeedVerifierInitialize is UninitializedFeedVerifier {
    function test_RevertWhen_Initialize_InvalidAddress() public {
        IBLS blsNull;
        vm.expectRevert(InvalidAddress.selector);
        feedVerifier.initialize(address(this), blsNull, bn256G2, eoracleChainId);
    }

    function test_Initialize() public {
        feedVerifier.initialize(address(this), bls, bn256G2, eoracleChainId);
        assertEq(address(feedVerifier.bls()), address(bls));
        assertEq(address(feedVerifier.bn256G2()), address(bn256G2));
        assertEq(feedVerifier.eoracleChainId(), eoracleChainId);
        assertEq(feedVerifier.owner(), address(this));
    }

    function test_RevertWhen_Verify_NotInitialized() public {
        IEOFeedVerifier.LeafInput memory input = _getDefaultInput();
        IEOFeedVerifier.Checkpoint memory checkpoint = _getDefaultCheckpoint();
        uint256[2] memory signature = aggMessagePoints[0];
        bytes memory bitmap = bitmaps[0];

        vm.expectRevert(CallerIsNotFeedManager.selector);
        feedVerifier.verify(input, checkpoint, signature, bitmap);
    }
}

contract EOFeedVerifierTest is InitializedFeedVerifier {
    function test_SetFeedManager() public {
        address feedManagerAddr = makeAddr("feedManager");
        feedVerifier.setFeedManager(feedManagerAddr);
        assertEq(feedVerifier.feedManager(), feedManagerAddr);
    }

    function test_RevertWhen_SetFeedManagerInvalidAddress() public {
        vm.expectRevert(InvalidAddress.selector);
        feedVerifier.setFeedManager(address(0));
    }

    function test_verify() public {
        IEOFeedVerifier.LeafInput memory input = _getDefaultInput();
        IEOFeedVerifier.Checkpoint memory checkpoint = _getDefaultCheckpoint();

        bytes32 eventRoot = hashes[0];
        uint256 blockNumber = 1;

        uint256[2] memory signature = aggMessagePoints[0];
        bytes memory bitmap = bitmaps[0];

        (,,, bytes memory data) = abi.decode(input.unhashedLeaf, (uint256, address, address, bytes));
        bytes memory leafData = feedVerifier.verify(input, checkpoint, signature, bitmap);
        assertEq(leafData, data);
        assertEq(feedVerifier.lastProcessedBlockNumber(), blockNumber);
        assertEq(feedVerifier.lastProcessedEventRoot(), eventRoot);
    }

    function test_RevertWhen_Verify_CalledByNotFeedManager() public {
        IEOFeedVerifier.LeafInput memory input = _getDefaultInput();
        IEOFeedVerifier.Checkpoint memory checkpoint = _getDefaultCheckpoint();

        uint256[2] memory signature = aggMessagePoints[0];
        bytes memory bitmap = bitmaps[0];

        vm.expectRevert(CallerIsNotFeedManager.selector);
        vm.prank(alice);
        feedVerifier.verify(input, checkpoint, signature, bitmap);
    }

    function test_RevertWhen_Verify_InvalidEventRoot() public {
        IEOFeedVerifier.LeafInput memory input = _getDefaultInput();
        IEOFeedVerifier.Checkpoint memory checkpoint = _getDefaultCheckpoint();

        uint256[2] memory signature = aggMessagePoints[0];
        bytes memory bitmap = bitmaps[0];

        feedVerifier.verify(input, checkpoint, signature, bitmap);

        checkpoint.eventRoot = bytes32(0);

        vm.expectRevert(InvalidEventRoot.selector);
        feedVerifier.verify(input, checkpoint, signature, bitmap);
    }

    function test_RevertWhen_AggVotingPowerIsZero_Verify() public {
        IEOFeedVerifier.LeafInput memory input = _getDefaultInput();
        IEOFeedVerifier.Checkpoint memory checkpoint = _getDefaultCheckpoint();

        uint256[2] memory signature = aggMessagePoints[0];
        // empty bitmap creates zero voting power
        bytes memory bitmap;

        vm.expectRevert(AggVotingPowerIsZero.selector);
        feedVerifier.verify(input, checkpoint, signature, bitmap);
    }

    function test_RevertWhen_InsufficientVotingPower_Verify() public {
        IEOFeedVerifier.LeafInput memory input = _getDefaultInput();
        IEOFeedVerifier.Checkpoint memory checkpoint = _getDefaultCheckpoint();

        uint256[2] memory signature = aggMessagePoints[0];
        // bitmap has one bit set
        bytes memory bitmap = abi.encodePacked(uint8(1));

        vm.expectRevert(InsufficientVotingPower.selector);
        feedVerifier.verify(input, checkpoint, signature, bitmap);
    }

    function test_RevertIf_DataIsAltered_Verify() public {
        IEOFeedVerifier.LeafInput memory input = _getDefaultInput();
        IEOFeedVerifier.Checkpoint memory checkpoint = _getDefaultCheckpoint();

        //alter one byte in the leaf unhashed data
        input.unhashedLeaf[0] = input.unhashedLeaf[0] == bytes1(0x10) ? bytes1(0x20) : bytes1(0x10);
        uint256[2] memory signature = aggMessagePoints[0];
        bytes memory bitmap = bitmaps[0];

        vm.expectRevert(InvalidProof.selector);
        feedVerifier.verify(input, checkpoint, signature, bitmap);
    }

    function test_RevertWhen_Verify_WithEmptyValidatorSet() public {
        IEOFeedVerifier.LeafInput memory input = _getDefaultInput();
        IEOFeedVerifier.Checkpoint memory checkpoint = _getDefaultCheckpoint();
        uint256[2] memory signature = aggMessagePoints[0];
        bytes memory bitmap = bitmaps[0];
        IEOFeedVerifier.Validator[] memory emptyValidatorSet;
        feedVerifier.setNewValidatorSet(emptyValidatorSet);

        vm.expectRevert(AggVotingPowerIsZero.selector);
        feedVerifier.verify(input, checkpoint, signature, bitmap);
    }

    function test_batchVerify() public {
        IEOFeedVerifier.LeafInput[] memory inputs = new IEOFeedVerifier.LeafInput[](1);
        IEOFeedVerifier.Checkpoint memory checkpoint = _getDefaultCheckpoint();

        inputs[0] = _getDefaultInput();

        uint256[2] memory signature = aggMessagePoints[0];

        feedVerifier.batchVerify(inputs, checkpoint, signature, bitmaps[0]);
    }

    function test_RevertWhen_BatchVerify_CalledByNotFeedManager() public {
        IEOFeedVerifier.LeafInput[] memory inputs = new IEOFeedVerifier.LeafInput[](1);
        IEOFeedVerifier.Checkpoint memory checkpoint = _getDefaultCheckpoint();
        inputs[0] = _getDefaultInput();

        uint256[2] memory signature = aggMessagePoints[0];

        vm.expectRevert(CallerIsNotFeedManager.selector);
        vm.prank(alice);
        feedVerifier.batchVerify(inputs, checkpoint, signature, bitmaps[0]);
    }

    function test_RevertWhen_BatchVerify_InvalidEventRoot() public {
        IEOFeedVerifier.LeafInput[] memory inputs = new IEOFeedVerifier.LeafInput[](1);
        IEOFeedVerifier.Checkpoint memory checkpoint = _getDefaultCheckpoint();
        inputs[0] = _getDefaultInput();

        uint256[2] memory signature = aggMessagePoints[0];
        // solhint-disable-next-line func-named-parameters

        feedVerifier.batchVerify(inputs, checkpoint, signature, bitmaps[0]);

        checkpoint.eventRoot = bytes32(0);

        vm.expectRevert(InvalidEventRoot.selector);
        feedVerifier.batchVerify(inputs, checkpoint, signature, bitmaps[0]);
    }

    function test_SetNewValidatorSet() public {
        feedVerifier.setNewValidatorSet(validatorSet);
        uint256 totalPower = 0;
        bytes32 validatorSetHash = keccak256(abi.encode(validatorSet));
        assertEq(feedVerifier.currentValidatorSetLength(), validatorSetSize);
        assertEq(feedVerifier.currentValidatorSetHash(), validatorSetHash);
        for (uint256 i = 0; i < validatorSetSize; i++) {
            IEOFeedVerifier.Validator memory validator = feedVerifier.currentValidatorSet(i);
            assertEq(validator._address, validatorSet[i]._address);
            assertEq(validator.votingPower, validatorSet[i].votingPower);
            totalPower += validator.votingPower;
        }
        assertEq(feedVerifier.totalVotingPower(), totalPower);
    }

    function test_RevertWhen_VotingPowerIsZero_SetNewValidatorSet() public {
        validatorSet[0].votingPower = 0;
        vm.expectRevert(VotingPowerIsZero.selector);
        feedVerifier.setNewValidatorSet(validatorSet);
    }
}
