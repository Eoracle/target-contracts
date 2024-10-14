// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { stdJson } from "forge-std/Script.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Vm } from "forge-std/Vm.sol";

library EOJsonUtils {
    using stdJson for string;

    struct Config {
        uint256 eoracleChainId;
        address proxyAdminOwner;
        address[] publishers;
        uint256[] supportedFeedIds;
        FeedData[] supportedFeedsData;
        uint256 targetChainId;
        address targetContractsOwner;
        bool usePrecompiledModexp;
    }

    struct FeedData {
        address base;
        uint256 decimals;
        string description;
        uint256 feedId;
        address quote;
    }

    // Cheat code address, 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D.
    address internal constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    string internal constant OUTPUT_CONFIG = "outputConfigJsonKey";
    Vm internal constant VM = Vm(VM_ADDRESS);

    function initOutputConfig() internal returns (string memory) {
        string memory outputConfig = getOutputConfig();
        OUTPUT_CONFIG.serialize(outputConfig);
        return outputConfig;
    }

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

    function getParsedConfig() internal view returns (Config memory) {
        string memory config = getConfig();
        bytes memory configRaw = config.parseRaw(".");
        return abi.decode(configRaw, (Config));
    }

    function getOutputConfig() internal view returns (string memory) {
        string memory path = getFilePath("targetContractAddresses.json");
        return VM.readFile(path);
    }

    function getFilePath(string memory fileName) internal view returns (string memory) {
        uint256 eoracleChainId = VM.envUint("EORACLE_CHAIN_ID");
        return string.concat(
            "script/config/", Strings.toString(block.chainid), "/", Strings.toString(eoracleChainId), "/", fileName
        );
    }

    function addressToString(address _address) internal pure returns (string memory) {
        return Strings.toHexString(uint256(uint160(_address)), 20);
    }
}
