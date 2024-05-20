// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Test } from "forge-std/Test.sol";
import { stdJson } from "forge-std/Script.sol";
import { DeployNewTargetContractSet } from "../script/deployment/DeployNewTargetContractSet.s.sol";
import { DeployFeedRegistryAdapter } from "../script/deployment/DeployFeedRegistryAdapter.s.sol";
import { DeployFeeds } from "../script/deployment/DeployFeeds.s.sol";
import { SetupCoreContracts } from "../script/deployment/setup/SetupCoreContracts.s.sol";
import { EOFeedVerifier } from "../src/EOFeedVerifier.sol";
import { EOFeedRegistry } from "../src/EOFeedRegistry.sol";
import { EOFeedRegistryAdapter } from "../src/adapters/EOFeedRegistryAdapter.sol";
import { EOJsonUtils } from "script/utils/EOJsonUtils.sol";
import { IEOFeed } from "../src/adapters/interfaces/IEOFeed.sol";

contract DeployScriptTest is Test {
    using stdJson for string;

    DeployNewTargetContractSet public mainDeployer;
    DeployFeedRegistryAdapter public adapterDeployer;
    SetupCoreContracts public coreContractsSetup;
    DeployFeeds public feedsDeployer;
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
        coreContractsSetup = new SetupCoreContracts();
        feedsDeployer = new DeployFeeds();

        config = EOJsonUtils.getConfig();
        targetContractsOwner = config.readAddress(".targetContractsOwner");

        (bls, bn256G2, feedVerifierProxy, feedRegistryProxy) = mainDeployer.run();
        (feedImplementation, adapterProxy) = adapterDeployer.run();
        coreContractsSetup.run(targetContractsOwner);
        feedsDeployer.run(targetContractsOwner);
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

    function test_SetupCoreContracts() public view {
        EOJsonUtils.Config memory configStructured = EOJsonUtils.getParsedConfig();
        uint16 symbolId;
        for (uint256 i = 0; i < configStructured.supportedSymbols.length; i++) {
            symbolId = uint16(configStructured.supportedSymbols[i]);
            assertTrue(EOFeedRegistry(feedRegistryProxy).isSupportedSymbol(symbolId));
        }
        for (uint256 i = 0; i < configStructured.publishers.length; i++) {
            assertTrue(EOFeedRegistry(feedRegistryProxy).isWhitelistedPublisher(configStructured.publishers[i]));
        }
    }

    function test_DeployFeeds() public view {
        EOJsonUtils.Config memory configStructured = EOJsonUtils.getParsedConfig();
        uint256 symbolLength = configStructured.supportedSymbolsData.length;

        for (uint256 i = 0; i < symbolLength; i++) {
            uint16 symbolId = uint16(configStructured.supportedSymbolsData[i].symbolId);
            IEOFeed feed = EOFeedRegistryAdapter(adapterProxy).getFeedByPairSymbol(symbolId);
            IEOFeed feedByAddresses = EOFeedRegistryAdapter(adapterProxy).getFeed(
                configStructured.supportedSymbolsData[i].base, configStructured.supportedSymbolsData[i].quote
            );
            assertEq(address(feed), address(feedByAddresses));
            assertEq(feed.getPairSymbol(), symbolId);
            assertEq(feed.description(), configStructured.supportedSymbolsData[i].description);
            assertEq(feed.decimals(), uint8(configStructured.supportedSymbolsData[i].decimals));
            assertEq(feed.version(), 1);
        }
    }

    // revert the changes to the config made by this test suite
    // solhint-disable-next-line ordering
    function test_Cleanup() public {
        EOJsonUtils.writeConfig(initialOutputConfig);
    }
}
