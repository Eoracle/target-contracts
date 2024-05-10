// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { stdJson } from "forge-std/Script.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Vm } from "forge-std/Vm.sol";

library EOJsonUtils {
    using stdJson for string;

    // Cheat code address, 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D.
    address internal constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    Vm internal constant VM = Vm(VM_ADDRESS);

    function writeConfig(string memory value, string memory key) internal {
        string memory path = getFilePath("targetContractAddresses.json");
        VM.writeJson(value, path, key);
    }

    function writeConfig(string memory config) internal {
        string memory path = getFilePath("targetContractAddresses.json");
        VM.writeJson(config, path);
    }

    function getConfig() internal view returns (string memory) {
        string memory path = getFilePath("targetContractSetConfig.json");
        return VM.readFile(path);
    }

    function getOutputConfig() internal view returns (string memory) {
        string memory path = getFilePath("targetContractAddresses.json");
        return VM.readFile(path);
    }

    function getFilePath(string memory fileName) internal view returns (string memory) {
        uint256 childChainId = VM.envUint("CHILD_CHAIN_ID");
        return string.concat(
            "script/config/", Strings.toString(block.chainid), "/", Strings.toString(childChainId), "/", fileName
        );
    }
}
