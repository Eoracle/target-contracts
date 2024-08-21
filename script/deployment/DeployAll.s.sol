// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/Script.sol";
import { DeployNewTargetContractSet } from "./DeployNewTargetContractSet.s.sol";
import { DeployFeedRegistryAdapter } from "./DeployFeedRegistryAdapter.s.sol";
import { DeployFeeds } from "./DeployFeeds.s.sol";
import { SetupCoreContracts } from "./setup/SetupCoreContracts.s.sol";
import { SetValidators } from "./setup/SetValidators.s.sol";

contract DeployAll is Script {
    using stdJson for string;

    DeployNewTargetContractSet public mainDeployer;
    DeployFeedRegistryAdapter public adapterDeployer;
    SetupCoreContracts public coreContractsSetup;
    DeployFeeds public feedsDeployer;
    SetValidators public setValidators;

    function run() public {
        mainDeployer = new DeployNewTargetContractSet();
        coreContractsSetup = new SetupCoreContracts();
        adapterDeployer = new DeployFeedRegistryAdapter();
        feedsDeployer = new DeployFeeds();
        setValidators = new SetValidators();

        mainDeployer.run();
        coreContractsSetup.run();
        adapterDeployer.run();
        feedsDeployer.run();
        setValidators.run();
    }
}
