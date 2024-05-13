// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { Script } from "forge-std/Script.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { EOJsonUtils } from "script/utils/EOJsonUtils.sol";
import { Denominations } from "../../src/libraries/Denominations.sol";

contract DeployLibDenominations is Script {
    function run() external returns (address feedImplementation, address adapterProxy) {
        vm.startBroadcast();

        address libDenominations = _deployLibDenominations(bytes32(block.timestamp));
        EOJsonUtils.writeConfig(Strings.toHexString(address(libDenominations)), ".libDenominations");
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
