// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test } from "forge-std/Test.sol";
import { stdJson } from "forge-std/Script.sol";
import { DeployNewTargetContractSet } from "../script/deployment/DeployNewTargetContractSet.s.sol";
import { DeployFeedRegistryAdapter } from "../script/deployment/DeployFeedRegistryAdapter.s.sol";
import { TargetCheckpointManager } from "../src/TargetCheckpointManager.sol";
import { EOFeedVerifier } from "../src/EOFeedVerifier.sol";
import { EOFeedRegistry } from "../src/EOFeedRegistry.sol";
import { EOFeedRegistryAdapter } from "../src/adapters/EOFeedRegistryAdapter.sol";

contract DeployScriptTest is Test {
    using stdJson for string;

    DeployNewTargetContractSet public mainDeployer;
    DeployFeedRegistryAdapter public adapterDeployer;
    address public bls;
    address public bn256G2;
    address public proxyAdmin;
    address public checkpointManagerProxy;
    address public feedVerifierProxy;
    address public feedRegistryProxy;
    address public feedImplementation;
    address public adapterProxy;
    string public config;
    string public addressesConfig;
    address public targetContractsOwner;

    function setUp() public {
        mainDeployer = new DeployNewTargetContractSet();
        adapterDeployer = new DeployFeedRegistryAdapter();

        (bls, bn256G2, proxyAdmin, checkpointManagerProxy, feedVerifierProxy, feedRegistryProxy) = mainDeployer.run();
        (feedImplementation, adapterProxy) = adapterDeployer.run();

        config = vm.readFile("script/config/targetContractSetConfig.json");
        targetContractsOwner = config.readAddress(".targetContractsOwner");

        addressesConfig = vm.readFile("script/config/targetContractAddresses.json");
    }

    function test_Deploy_CheckpointManager() public view {
        uint256 chainId = config.readUint(".chainId");

        assertEq(TargetCheckpointManager(checkpointManagerProxy).owner(), targetContractsOwner);
        assertEq(TargetCheckpointManager(checkpointManagerProxy).chainId(), chainId);
        assertEq(address(TargetCheckpointManager(checkpointManagerProxy).bls()), bls);
        assertEq(address(TargetCheckpointManager(checkpointManagerProxy).bn256G2()), bn256G2);
        assertEq(checkpointManagerProxy, addressesConfig.readAddress(".checkpointManager"));
    }

    function test_Deploy_FeedVerifier() public view {
        assertEq(EOFeedVerifier(feedVerifierProxy).owner(), targetContractsOwner);
        assertEq(address(EOFeedVerifier(feedVerifierProxy).getCheckpointManager()), checkpointManagerProxy);
        assertEq(feedVerifierProxy, addressesConfig.readAddress(".feedVerifier"));
    }

    function test_Deploy_FeedRegistry() public view {
        assertEq(EOFeedRegistry(feedRegistryProxy).owner(), targetContractsOwner);
        assertEq(address(EOFeedRegistry(feedRegistryProxy).getFeedVerifier()), feedVerifierProxy);
        assertEq(feedRegistryProxy, addressesConfig.readAddress(".feedRegistry"));
    }

    function test_Deploy_FeedRegistryAdapter() public view {
        assertEq(EOFeedRegistryAdapter(adapterProxy).owner(), targetContractsOwner);
        assertEq(address(EOFeedRegistryAdapter(adapterProxy).getFeedRegistry()), feedRegistryProxy);
        assertEq(adapterProxy, addressesConfig.readAddress(".feedRegistryAdapter"));
    }
}
