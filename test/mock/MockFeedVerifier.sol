// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IEOFeedVerifier } from "../../src/interfaces/IEOFeedVerifier.sol";

contract MockFeedVerifier is IEOFeedVerifier {
    Validator[] public validatorSet;

    function setNewValidatorSet(Validator[] calldata newValidatorSet) external {
        delete validatorSet;
        for (uint256 i = 0; i < newValidatorSet.length; i++) {
            validatorSet.push(newValidatorSet[i]);
        }
    }

    function verifySignature(Checkpoint calldata, uint256[2] calldata, bytes calldata) public pure {
        return;
    }

    function verifyLeaf(LeafInput calldata input, bytes32) public pure returns (bytes memory) {
        (,,, bytes memory data) = abi.decode(input.unhashedLeaf, (uint256, address, address, bytes));
        return data;
    }

    function verifyLeaves(LeafInput[] calldata inputs, bytes32) public pure returns (bytes[] memory) {
        uint256 length = inputs.length;
        bytes[] memory returnData = new bytes[](length);
        for (uint256 i = 0; i < length; i++) {
            (,,, bytes memory data) = abi.decode(inputs[i].unhashedLeaf, (uint256, address, address, bytes));
            returnData[i] = data;
        }
        return returnData;
    }
}
