// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Test } from "forge-std/Test.sol";
import { stdJson } from "forge-std/Script.sol";
import { DeployNewTargetContractSet } from "../script/deployment/DeployNewTargetContractSet.s.sol";
import { DeployFeedRegistryAdapter } from "../script/deployment/DeployFeedRegistryAdapter.s.sol";
import { DeployFeeds } from "../script/deployment/DeployFeeds.s.sol";
import { SetupCoreContracts } from "../script/deployment/setup/SetupCoreContracts.s.sol";
import { EOFeedVerifier } from "../src/EOFeedVerifier.sol";
import { EOFeedManager } from "../src/EOFeedManager.sol";
import { EOFeedRegistryAdapter } from "../src/adapters/EOFeedRegistryAdapter.sol";
import { EOJsonUtils } from "script/utils/EOJsonUtils.sol";
import { IEOFeedAdapter } from "../src/adapters/interfaces/IEOFeedAdapter.sol";

contract DeployScriptTest is Test {
    using stdJson for string;

    DeployNewTargetContractSet public mainDeployer;
    DeployFeedRegistryAdapter public adapterDeployer;
    SetupCoreContracts public coreContractsSetup;
    DeployFeeds public feedsDeployer;
    address public bls;
    address public bn256G2;
    address public feedVerifierProxy;
    address public feedManagerProxy;
    address public feedAdapterImplementation;
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

        (bls, bn256G2, feedVerifierProxy, feedManagerProxy) = mainDeployer.run(address(this));
        (feedAdapterImplementation, adapterProxy) = adapterDeployer.run();
        coreContractsSetup.run(targetContractsOwner);
        feedsDeployer.run(targetContractsOwner);
        outputConfig = EOJsonUtils.getOutputConfig();
    }

    function test_Deploy_FeedVerifier() public view {
        uint256 eoracleChainId = config.readUint(".eoracleChainId");
        assertEq(EOFeedVerifier(feedVerifierProxy).owner(), targetContractsOwner);
        assertEq(EOFeedVerifier(feedVerifierProxy).eoracleChainId(), eoracleChainId);
        assertEq(address(EOFeedVerifier(feedVerifierProxy).bls()), bls);
        assertEq(address(EOFeedVerifier(feedVerifierProxy).bn256G2()), bn256G2);
        assertEq(feedVerifierProxy, outputConfig.readAddress(".feedVerifier"));
    }

    function test_Deploy_FeedManager() public view {
        assertEq(EOFeedManager(feedManagerProxy).owner(), targetContractsOwner);
        assertEq(address(EOFeedManager(feedManagerProxy).getFeedVerifier()), feedVerifierProxy);
        assertEq(feedManagerProxy, outputConfig.readAddress(".feedManager"));
    }

    function test_Deploy_FeedRegistryAdapter() public view {
        assertEq(EOFeedRegistryAdapter(adapterProxy).owner(), targetContractsOwner);
        assertEq(address(EOFeedRegistryAdapter(adapterProxy).getFeedManager()), feedManagerProxy);
        assertEq(adapterProxy, outputConfig.readAddress(".feedRegistryAdapter"));
    }

    function test_SetupCoreContracts() public view {
        EOJsonUtils.Config memory configStructured = EOJsonUtils.getParsedConfig();
        uint16 feedId;
        for (uint256 i = 0; i < configStructured.supportedFeedIds.length; i++) {
            feedId = uint16(configStructured.supportedFeedIds[i]);
            assertTrue(EOFeedManager(feedManagerProxy).isSupportedFeed(feedId));
        }
        for (uint256 i = 0; i < configStructured.publishers.length; i++) {
            assertTrue(EOFeedManager(feedManagerProxy).isWhitelistedPublisher(configStructured.publishers[i]));
        }
    }

    function test_DeployFeeds() public view {
        EOJsonUtils.Config memory configStructured = EOJsonUtils.getParsedConfig();
        uint256 feedsLength = configStructured.supportedFeedsData.length;

        for (uint256 i = 0; i < feedsLength; i++) {
            uint16 feedId = uint16(configStructured.supportedFeedsData[i].feedId);
            IEOFeedAdapter feedAdapter = EOFeedRegistryAdapter(adapterProxy).getFeedById(feedId);
            IEOFeedAdapter feedByAddresses = EOFeedRegistryAdapter(adapterProxy).getFeed(
                configStructured.supportedFeedsData[i].base, configStructured.supportedFeedsData[i].quote
            );
            assertEq(address(feedAdapter), address(feedByAddresses));
            assertEq(feedAdapter.getFeedId(), feedId);
            assertEq(feedAdapter.description(), configStructured.supportedFeedsData[i].description);
            assertEq(feedAdapter.decimals(), uint8(configStructured.supportedFeedsData[i].outputDecimals));
            assertEq(feedAdapter.version(), 1);
        }
    }

    // revert the changes to the config made by this test suite
    // solhint-disable-next-line ordering
    function test_Cleanup() public {
        EOJsonUtils.writeConfig(initialOutputConfig);
    }
}
