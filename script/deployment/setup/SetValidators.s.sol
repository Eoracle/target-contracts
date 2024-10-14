// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/Script.sol";
import { EOJsonUtils } from "../../utils/EOJsonUtils.sol";
import { EOFeedVerifier } from "../../../src/EOFeedVerifier.sol";
import { IEOFeedVerifier } from "../../../src/interfaces/IEOFeedVerifier.sol";

contract SetValidators is Script {
    using stdJson for string;

    EOFeedVerifier public feedVerifier;
    EOFeedVerifier public rootChainfeedVerifier;
    uint256 public currentForkId;

    function run() public {
        IEOFeedVerifier.Validator[] memory validators = _readValidatorsFromRootChain();
        _setValidatorsOnTargetChain(validators);
    }

    function _readValidatorsFromRootChain() internal returns (IEOFeedVerifier.Validator[] memory validators) {
        // switch to the root chain to read the current validator set
        currentForkId = vm.createSelectFork(vm.envString("ROOT_RPC_URL"));
        rootChainfeedVerifier = EOFeedVerifier(vm.envAddress("ROOT_VERIFIER_ADDRESS"));

        uint256 validatorsLength = rootChainfeedVerifier.currentValidatorSetLength();
        validators = new IEOFeedVerifier.Validator[](validatorsLength);
        for (uint256 i = 0; i < validatorsLength; i++) {
            validators[i] = rootChainfeedVerifier.currentValidatorSet(i);
        }
    }

    function _setValidatorsOnTargetChain(IEOFeedVerifier.Validator[] memory newValidatorSet) internal {
        // switch back to the target chain to set the new validator set
        vm.selectFork(currentForkId - 1);
        string memory outputConfig = EOJsonUtils.getOutputConfig();
        feedVerifier = EOFeedVerifier(outputConfig.readAddress(".feedVerifier"));

        uint256 broadcastFrom = vm.envUint("OWNER_PRIVATE_KEY");
        vm.startBroadcast(broadcastFrom);
        feedVerifier.setNewValidatorSet(newValidatorSet);
        vm.stopBroadcast();
    }
}
