// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IEOFeedVerifier } from "../../src/interfaces/IEOFeedVerifier.sol";
import { IBLS } from "../../src/interfaces/IBLS.sol";
import { UninitializedFeedVerifier, InitializedFeedVerifier } from "./EOFeedVerifierBase.t.sol";
import { InvalidProof, InvalidAddress, VotingPowerIsZero } from "../../src/interfaces/Errors.sol";

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
}

contract EOFeedVerifierTest is InitializedFeedVerifier {
    function test_verify() public {
        IEOFeedVerifier.LeafInput memory input =
            IEOFeedVerifier.LeafInput({ unhashedLeaf: unhashedLeaves[0], leafIndex: 0, proof: proves[0] });

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

        (uint256 id,,, bytes memory data) = abi.decode(input.unhashedLeaf, (uint256, address, address, bytes));
        vm.expectEmit(true, true, true, true);
        emit LeafVerified(id, data);
        bytes memory leafData = feedVerifier.verify(input, checkpoint, signature, bitmap);
        assertEq(leafData, data);
    }

    function test_RevertIf_DataIsAltered_Verify() public {
        IEOFeedVerifier.LeafInput memory input =
            IEOFeedVerifier.LeafInput({ unhashedLeaf: unhashedLeaves[0], leafIndex: 0, proof: proves[0] });

        //alter one byte in the leaf unhashed data
        input.unhashedLeaf[0] = input.unhashedLeaf[0] == bytes1(0x10) ? bytes1(0x20) : bytes1(0x10);
        uint256[2] memory signature = aggMessagePoints[0];
        bytes memory bitmap = bitmaps[0];

        IEOFeedVerifier.Checkpoint memory checkpoint = IEOFeedVerifier.Checkpoint({
            epoch: 1,
            blockNumber: 1,
            eventRoot: hashes[0],
            blockHash: hashes[1],
            blockRound: 0
        });
        vm.expectRevert(InvalidProof.selector);
        feedVerifier.verify(input, checkpoint, signature, bitmap);
    }

    function test_batchVerify() public {
        IEOFeedVerifier.LeafInput[] memory inputs = new IEOFeedVerifier.LeafInput[](1);

        IEOFeedVerifier.Checkpoint memory checkpoint = IEOFeedVerifier.Checkpoint({
            epoch: 1,
            blockNumber: 1,
            eventRoot: hashes[0],
            blockHash: hashes[1],
            blockRound: 0
        });
        inputs[0] = IEOFeedVerifier.LeafInput({ unhashedLeaf: unhashedLeaves[0], leafIndex: 0, proof: proves[0] });
        (uint256 id,,, bytes memory data) = abi.decode(inputs[0].unhashedLeaf, (uint256, address, address, bytes));

        uint256[2] memory signature = aggMessagePoints[0];
        // solhint-disable-next-line func-named-parameters

        vm.expectEmit(true, true, true, true);
        emit LeafVerified(id, data);
        feedVerifier.batchVerify(inputs, checkpoint, signature, bitmaps[0]);
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
}
