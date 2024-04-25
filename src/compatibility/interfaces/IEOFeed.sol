// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { AggregatorV3Interface } from "./AggregatorV3Interface.sol";

interface IEOFeed is AggregatorV3Interface {
    function initialize(address feedRegistry, uint8 decimals, string memory description, uint256 version) external;
}
