// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IEOFeedVerifier } from "../../src/interfaces/IEOFeedVerifier.sol";

contract MockFeedVerifier is IEOFeedVerifier {
    Validator[] public validatorSet;

    function verify(
        LeafInput memory input,
        Checkpoint calldata,
        uint256[2] calldata,
        bytes calldata
    )
        external
        returns (bytes memory leafData)
    {
        (,,, bytes memory data) = abi.decode(input.unhashedLeaf, (uint256, address, address, bytes));
        return data;
    }

    function batchVerify(
        LeafInput[] memory inputs,
        Checkpoint calldata,
        uint256[2] calldata,
        bytes calldata
    )
        external
        returns (bytes[] memory leafData)
    {
        uint256 length = inputs.length;
        bytes[] memory returnData = new bytes[](length);
        for (uint256 i = 0; i < length; i++) {
            (,,, bytes memory data) = abi.decode(inputs[i].unhashedLeaf, (uint256, address, address, bytes));
            returnData[i] = data;
        }
        return returnData;
    }

    function setNewValidatorSet(Validator[] calldata newValidatorSet) external {
        delete validatorSet;
        for (uint256 i = 0; i < newValidatorSet.length; i++) {
            validatorSet.push(newValidatorSet[i]);
        }
    }
}
