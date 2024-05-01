// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { EOFeedFactoryClone } from "./factories/EOFeedFactoryClone.sol";
import { EOFeedRegistryAdapterBase } from "./EOFeedRegistryAdapterBase.sol";

/**
 * @title EOFeedRegistryAdapterClone
 * @notice The adapter of EOFeedRegistry contract for CL FeedRegistry
 * @dev This contract uses the clone pattern for deploying EOFeed instances
 */
// solhint-disable no-empty-blocks
contract EOFeedRegistryAdapterClone is EOFeedRegistryAdapterBase, EOFeedFactoryClone { }
