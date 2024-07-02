// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { Script } from "forge-std/Script.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { EOFeedVerifier } from "src/EOFeedVerifier.sol";
import { IBLS } from "src/interfaces/IBLS.sol";
import { IBN256G2 } from "src/interfaces/IBN256G2.sol";

abstract contract FeedVerifierDeployer is Script {
    function deployFeedVerifier(
        address proxyAdmin,
        address owner,
        IBLS bls,
        IBN256G2 bn256G2,
        uint256 eoracleChainId,
        address[] memory allowedSenders
    )
        internal
        returns (address proxyAddr)
    {
        bytes memory initData =
            abi.encodeCall(EOFeedVerifier.initialize, (owner, bls, bn256G2, eoracleChainId, allowedSenders));

        proxyAddr = Upgrades.deployTransparentProxy("EOFeedVerifier.sol", proxyAdmin, initData);
    }
}

contract DeployFeedVerifier is FeedVerifierDeployer {
    function run(
        address proxyAdmin,
        address owner,
        IBLS bls,
        IBN256G2 bn256G2,
        uint256 eoracleChainId,
        address[] calldata allowedSenders
    )
        external
        returns (address proxyAddr)
    {
        return deployFeedVerifier(proxyAdmin, owner, bls, bn256G2, eoracleChainId, allowedSenders);
    }
}
