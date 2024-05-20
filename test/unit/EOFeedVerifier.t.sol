// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IEOFeedVerifier } from "../../src/interfaces/IEOFeedVerifier.sol";
import { IBLS } from "../../src/interfaces/IBLS.sol";
import { IBN256G2 } from "../../src/interfaces/IBN256G2.sol";
import { UninitializedFeedVerifier, InitializedFeedVerifier } from "./EOFeedVerifierBase.t.sol";
import {
    InvalidProof,
    InvalidAddress,
    VotingPowerIsZero,
    InvalidEventRoot,
    AggVotingPowerIsZero,
    InsufficientVotingPower
} from "../../src/interfaces/Errors.sol";

contract EOFeedVerifierInitialize is UninitializedFeedVerifier {
    function test_RevertWhen_Initialize_BlsInvalidAddress() public {
        IBLS blsNull;
        vm.expectRevert(InvalidAddress.selector);
        feedVerifier.initialize(address(this), blsNull, bn256G2, childChainId);
    }

    function test_RevertWhen_Initialize_Bn256G2InvalidAddress() public {
        IBN256G2 bn256G2Null;
        vm.expectRevert(InvalidAddress.selector);
        feedVerifier.initialize(address(this), bls, bn256G2Null, childChainId);
    }

    function test_Initialize() public {
        feedVerifier.initialize(address(this), bls, bn256G2, childChainId);
        assertEq(address(feedVerifier.bls()), address(bls));
        assertEq(address(feedVerifier.bn256G2()), address(bn256G2));
        assertEq(feedVerifier.childChainId(), childChainId);
        assertEq(feedVerifier.owner(), address(this));
    }
}

contract EOFeedVerifierTest is InitializedFeedVerifier {
    function test_verifyLeaf() public {
        IEOFeedVerifier.LeafInput memory input =
            IEOFeedVerifier.LeafInput({ unhashedLeaf: unhashedLeaves[0], leafIndex: 0, proof: proves[0] });

        bytes32 eventRoot = hashes[0];
        (uint256 id,,, bytes memory data) = abi.decode(input.unhashedLeaf, (uint256, address, address, bytes));
        vm.expectEmit(true, true, true, true);
        emit LeafVerified(id, data);
        bytes memory leafData = feedVerifier.verifyLeaf(input, eventRoot);
        assertEq(leafData, data);
    }

    function test_RevertWhen_InvalidEventRoot_VerifySignature() public {
        // set invalid event root
        bytes32 eventRoot = bytes32(0);
        uint256 blockNumber = 1;

        IEOFeedVerifier.Checkpoint memory checkpoint = IEOFeedVerifier.Checkpoint({
            epoch: 1,
            blockNumber: blockNumber,
            eventRoot: eventRoot,
            blockHash: hashes[1],
            blockRound: 0
        });
        uint256[2] memory signature = aggMessagePoints[0];
        bytes memory bitmap = bitmaps[0];

        vm.expectRevert(InvalidEventRoot.selector);
        feedVerifier.verifySignature(checkpoint, signature, bitmap);
    }

    function test_RevertWhen_AggVotingPowerIsZero_VerifySignature() public {
        bytes32 eventRoot = hashes[0];
        uint256 blockNumber = 1;

        IEOFeedVerifier.Checkpoint memory checkpoint = IEOFeedVerifier.Checkpoint({
            epoch: 1,
            blockNumber: blockNumber,
            eventRoot: eventRoot,
            blockHash: hashes[1],
            blockRound: 0
        });
        uint256[2] memory signature = aggMessagePoints[0];
        // empty bitmap creates zero voting power
        bytes memory bitmap;

        vm.expectRevert(AggVotingPowerIsZero.selector);
        feedVerifier.verifySignature(checkpoint, signature, bitmap);
    }

    function test_RevertWhen_InsufficientVotingPower_VerifySignature() public {
        bytes32 eventRoot = hashes[0];
        uint256 blockNumber = 1;

        IEOFeedVerifier.Checkpoint memory checkpoint = IEOFeedVerifier.Checkpoint({
            epoch: 1,
            blockNumber: blockNumber,
            eventRoot: eventRoot,
            blockHash: hashes[1],
            blockRound: 0
        });
        uint256[2] memory signature = aggMessagePoints[0];
        // bitmap has one bit set
        bytes memory bitmap = abi.encodePacked(uint8(1));

        vm.expectRevert(InsufficientVotingPower.selector);
        feedVerifier.verifySignature(checkpoint, signature, bitmap);
    }

    function test_RevertWhen_InvalidProof_VerifyLeaf() public {
        bytes32[] memory invalidProof = new bytes32[](1);
        invalidProof[0] = bytes32(0);
        IEOFeedVerifier.LeafInput memory input =
            IEOFeedVerifier.LeafInput({ unhashedLeaf: unhashedLeaves[0], leafIndex: 0, proof: invalidProof });

        bytes32 eventRoot = hashes[0];

        vm.expectRevert(InvalidProof.selector);
        feedVerifier.verifyLeaf(input, eventRoot);
    }

    function test_RevertIf_DataIsAltered_VerifyLeaf() public {
        IEOFeedVerifier.LeafInput memory input =
            IEOFeedVerifier.LeafInput({ unhashedLeaf: unhashedLeaves[0], leafIndex: 0, proof: proves[0] });

        //alter one byte in the leaf unhashed data
        input.unhashedLeaf[0] = input.unhashedLeaf[0] == bytes1(0x10) ? bytes1(0x20) : bytes1(0x10);
        bytes32 eventRoot = hashes[0];

        vm.expectRevert(InvalidProof.selector);
        feedVerifier.verifyLeaf(input, eventRoot);
    }

    function test_batchVerifyLeaves() public {
        IEOFeedVerifier.LeafInput[] memory inputs = new IEOFeedVerifier.LeafInput[](1);
        bytes32 eventRoot = hashes[0];

        inputs[0] = IEOFeedVerifier.LeafInput({ unhashedLeaf: unhashedLeaves[0], leafIndex: 0, proof: proves[0] });
        (uint256 id,,, bytes memory data) = abi.decode(inputs[0].unhashedLeaf, (uint256, address, address, bytes));

        vm.expectEmit(true, true, true, true);
        emit LeafVerified(id, data);
        feedVerifier.verifyLeaves(inputs, eventRoot);
    }

    function test_SetNewValidatorSet() public {
        feedVerifier.setNewValidatorSet(validatorSet);
        uint256 totalPower = 0;
        bytes32 validatorSetHash = keccak256(abi.encode(validatorSet));
        assertEq(feedVerifier.currentValidatorSetLength(), validatorSetSize);
        assertEq(feedVerifier.currentValidatorSetHash(), validatorSetHash);
        for (uint256 i = 0; i < validatorSetSize; i++) {
            (address _address, uint256 votingPower) = feedVerifier.currentValidatorSet(i);
            assertEq(_address, validatorSet[i]._address);
            assertEq(votingPower, validatorSet[i].votingPower);
            totalPower += votingPower;
        }
        assertEq(feedVerifier.totalVotingPower(), totalPower);
    }

    function test_RevertWhen_VotingPowerIsZero_SetNewValidatorSet() public {
        validatorSet[0].votingPower = 0;
        vm.expectRevert(VotingPowerIsZero.selector);
        feedVerifier.setNewValidatorSet(validatorSet);
    }

    function test_verifySignature() public view {
        bytes32 eventRoot = hashes[0];
        uint256 blockNumber = 1;

        IEOFeedVerifier.Checkpoint memory checkpoint = IEOFeedVerifier.Checkpoint({
            epoch: 1,
            blockNumber: blockNumber,
            eventRoot: eventRoot,
            blockHash: hashes[1],
            blockRound: 0
        });
        uint256[2] memory signature = aggMessagePoints[0];
        bytes memory bitmap = bitmaps[0];

        feedVerifier.verifySignature(checkpoint, signature, bitmap);
    }
}
