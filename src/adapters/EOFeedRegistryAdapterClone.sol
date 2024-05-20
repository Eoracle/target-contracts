// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { EOFeedFactoryClone } from "./factories/EOFeedFactoryClone.sol";
import { EOFeedRegistryAdapterBase } from "./EOFeedRegistryAdapterBase.sol";

/**
 * @title EOFeedRegistryAdapterClone
 * @notice The adapter of EOFeedManager contract for CL FeedRegistry
 * @dev This contract uses the clone pattern for deploying EOFeedAdapter instances
 */
// solhint-disable no-empty-blocks
contract EOFeedRegistryAdapterClone is EOFeedRegistryAdapterBase, EOFeedFactoryClone { }
