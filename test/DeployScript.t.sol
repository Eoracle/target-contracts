// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Test } from "forge-std/Test.sol";
import { stdJson } from "forge-std/Script.sol";
import { DeployNewTargetContractSet } from "../script/deployment/DeployNewTargetContractSet.s.sol";
import { DeployFeedRegistryAdapter } from "../script/deployment/DeployFeedRegistryAdapter.s.sol";
import { EOFeedVerifier } from "../src/EOFeedVerifier.sol";
import { EOFeedRegistry } from "../src/EOFeedRegistry.sol";
import { EOFeedRegistryAdapter } from "../src/adapters/EOFeedRegistryAdapter.sol";
import { EOJsonUtils } from "script/utils/EOJsonUtils.sol";

contract DeployScriptTest is Test {
    using stdJson for string;

    DeployNewTargetContractSet public mainDeployer;
    DeployFeedRegistryAdapter public adapterDeployer;
    address public bls;
    address public bn256G2;
    address public feedVerifierProxy;
    address public feedRegistryProxy;
    address public feedImplementation;
    address public adapterProxy;
    string public config;
    string public initialOutputConfig;
    string public outputConfig;
    address public targetContractsOwner;

    function setUp() public {
        initialOutputConfig = EOJsonUtils.getOutputConfig();
        mainDeployer = new DeployNewTargetContractSet();
        adapterDeployer = new DeployFeedRegistryAdapter();

        (bls, bn256G2, feedVerifierProxy, feedRegistryProxy) = mainDeployer.run();
        (feedImplementation, adapterProxy) = adapterDeployer.run();

        config = EOJsonUtils.getConfig();
        targetContractsOwner = config.readAddress(".targetContractsOwner");

        outputConfig = EOJsonUtils.getOutputConfig();
    }

    function test_Deploy_FeedVerifier() public view {
        uint256 childChainId = config.readUint(".childChainId");
        assertEq(EOFeedVerifier(feedVerifierProxy).owner(), targetContractsOwner);
        assertEq(EOFeedVerifier(feedVerifierProxy).childChainId(), childChainId);
        assertEq(address(EOFeedVerifier(feedVerifierProxy).bls()), bls);
        assertEq(address(EOFeedVerifier(feedVerifierProxy).bn256G2()), bn256G2);
        assertEq(feedVerifierProxy, outputConfig.readAddress(".feedVerifier"));
    }

    function test_Deploy_FeedRegistry() public view {
        assertEq(EOFeedRegistry(feedRegistryProxy).owner(), targetContractsOwner);
        assertEq(address(EOFeedRegistry(feedRegistryProxy).getFeedVerifier()), feedVerifierProxy);
        assertEq(feedRegistryProxy, outputConfig.readAddress(".feedRegistry"));
    }

    function test_Deploy_FeedRegistryAdapter() public view {
        assertEq(EOFeedRegistryAdapter(adapterProxy).owner(), targetContractsOwner);
        assertEq(address(EOFeedRegistryAdapter(adapterProxy).getFeedRegistry()), feedRegistryProxy);
        assertEq(adapterProxy, outputConfig.readAddress(".feedRegistryAdapter"));
    }

    // revert the changes to the config made by this test suite
    // solhint-disable-next-line ordering
    function test_Cleanup() public {
        EOJsonUtils.writeConfig(initialOutputConfig);
    }
}
