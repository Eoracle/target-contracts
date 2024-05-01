// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { stdJson } from "forge-std/Script.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Vm } from "forge-std/Vm.sol";

library EOJsonUtils {
    using stdJson for string;

    // Cheat code address, 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D.
    address internal constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    Vm internal constant VM = Vm(VM_ADDRESS);

    function writeConfig(string memory value, string memory fileName, string memory key) internal {
        string memory path = string.concat("script/config/", Strings.toString(block.chainid), "/", fileName);
        VM.writeJson(value, path, key);
    }

    function getConfig(string memory fileName) internal view returns (string memory) {
        string memory path = string.concat("script/config/", Strings.toString(block.chainid), "/", fileName);
        return VM.readFile(path);
    }
}
