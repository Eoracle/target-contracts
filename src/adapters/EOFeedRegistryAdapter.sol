// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { EOFeedFactoryBeacon } from "./factories/EOFeedFactoryBeacon.sol";
import { EOFeedRegistryAdapterBase } from "./EOFeedRegistryAdapterBase.sol";

/**
 * @title EOFeedRegistryAdapterClone
 * @notice The adapter of EOFeedRegistry contract for CL FeedRegistry, uses the beacon
 * @dev This contract inherits EOFeedFactoryBeacon, uses the beacon proxy pattern for deploying EOFeed instances
 */
// solhint-disable no-empty-blocks
contract EOFeedRegistryAdapter is EOFeedRegistryAdapterBase, EOFeedFactoryBeacon { }
