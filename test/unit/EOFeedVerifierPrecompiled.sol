// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { EOFeedVerifierTest } from "./EOFeedVerifier.t.sol";
import { BN256G2v1 } from "../../src/common/BN256G2v1.sol";

contract EOFeedVerifierPrecompiledTest is EOFeedVerifierTest {
    function _setBN256G2() internal override {
        bn256G2 = new BN256G2v1();
    }
}
