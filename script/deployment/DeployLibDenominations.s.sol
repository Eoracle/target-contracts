// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/Script.sol";

import { EOJsonUtils } from "script/utils/EOJsonUtils.sol";
import { Denominations } from "../../src/libraries/Denominations.sol";

contract DeployLibDenominations is Script {
    using stdJson for string;

    function run() external returns (address libDenominations) {
        vm.startBroadcast();
        EOJsonUtils.initOutputConfig();

        libDenominations = _deployLibDenominations(bytes32(block.timestamp));
        string memory outputConfigJson = EOJsonUtils.OUTPUT_CONFIG.serialize("libDenominations", libDenominations);
        EOJsonUtils.writeConfig(outputConfigJson);
        vm.stopBroadcast();
    }

    /**
     * @notice Deploy Denominations library
     * @dev Deploys library with create2 opcode since libraries can not be deployed independently via new keyword or
     * create opcode
     */
    function _deployLibDenominations(bytes32 salt) internal returns (address libDenominations) {
        bytes memory bytecode = type(Denominations).creationCode;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            libDenominations := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(libDenominations)) { revert(0, 0) }
        }
    }
}
