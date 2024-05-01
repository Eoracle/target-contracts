// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test } from "forge-std/Test.sol";
import { Utils } from "../utils/Utils.sol";
import { IEOFeedRegistry } from "../../src/interfaces/IEOFeedRegistry.sol";
import { EOFeedRegistry } from "../../src/EOFeedRegistry.sol";

contract EOFeedRegistryTests is Test, Utils {
    IEOFeedRegistry private registry;

    function setUp() public {
        registry = new EOFeedRegistry();
    }
}
