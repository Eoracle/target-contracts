// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { stdJson } from "forge-std/Script.sol";
import { Script } from "forge-std/Script.sol";

import { BN256G2 } from "../../src/common/BN256G2.sol";
import { BN256G2v1 } from "../../src/common/BN256G2v1.sol";
import { EOJsonUtils } from "script/utils/EOJsonUtils.sol";

contract DeployBN256G2 is Script {
    using stdJson for string;

    function run() external {
        run(vm.addr(vm.envUint("PRIVATE_KEY")));
    }

    function run(address broadcastFrom) public returns (address bn256G2) {
        EOJsonUtils.Config memory configStructured = EOJsonUtils.getParsedConfig();

        require(configStructured.targetChainId == block.chainid, "Wrong chain id for this config.");

        require(
            configStructured.eoracleChainId == vm.envUint("EORACLE_CHAIN_ID"), "Wrong EORACLE_CHAIN_ID for this config."
        );

        vm.startBroadcast(broadcastFrom);

        EOJsonUtils.initOutputConfig();

        if (configStructured.usePrecompiledModexp) {
            bn256G2 = address(new BN256G2v1());
        } else {
            bn256G2 = address(new BN256G2());
        }
        string memory outputConfigJson = EOJsonUtils.OUTPUT_CONFIG.serialize("bn256G2", bn256G2);

        EOJsonUtils.writeConfig(outputConfigJson);
    }
}
