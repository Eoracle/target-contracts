// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { Script } from "forge-std/Script.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { EOFeedVerifier } from "src/EOFeedVerifier.sol";
import { IBLS } from "src/interfaces/IBLS.sol";

abstract contract FeedVerifierDeployer is Script {
    function deployFeedVerifier(
        address proxyAdmin,
        address owner,
        IBLS bls,
        uint256 eoracleChainId
    )
        internal
        returns (address proxyAddr)
    {
        bytes memory initData = abi.encodeCall(EOFeedVerifier.initialize, (owner, bls, eoracleChainId));

        proxyAddr = Upgrades.deployTransparentProxy("EOFeedVerifier.sol", proxyAdmin, initData);
    }
}

contract DeployFeedVerifier is FeedVerifierDeployer {
    function run(
        address proxyAdmin,
        address owner,
        IBLS bls,
        uint256 eoracleChainId
    )
        external
        returns (address proxyAddr)
    {
        return deployFeedVerifier(proxyAdmin, owner, bls, eoracleChainId);
    }
}
