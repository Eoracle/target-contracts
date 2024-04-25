// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { TargetCheckpointManager } from "../../src/TargetCheckpointManager.sol";
import { BLS } from "../../src/common/BLS.sol";
import { BN256G2 } from "../../src/common/BN256G2.sol";
import { Cheats } from "../utils/Cheats.sol";
import { ICheckpointManager } from "../../src/interfaces/ICheckpointManager.sol";

abstract contract UninitializedCheckpointManager is Test, Cheats {
    TargetCheckpointManager public checkpointManager;
    BLS public bls;
    BN256G2 public bn256G2;

    uint256 public validatorSetSize;
    ICheckpointManager.Validator[] public validatorSet;

    address public admin;
    address public alice;
    address public bob;
    bytes32 public constant DOMAIN = keccak256("DOMAIN_CHECKPOINT_MANAGER");
    bytes32[] public hashes;
    bytes32[] public proof;
    bytes[] public bitmaps;
    uint256[2][] public aggMessagePoints;
    uint256[] public aggVotingPowers;
    uint256 public childChainId;

    function setUp() public virtual {
        bls = new BLS();
        bn256G2 = new BN256G2();
        checkpointManager = TargetCheckpointManager(proxify("TargetCheckpointManager.sol", abi.encode(address(0))));

        admin = makeAddr("admin");
        alice = makeAddr("Alice");
        bob = makeAddr("Bob");

        string[] memory cmd = new string[](4);
        cmd[0] = "npx";
        cmd[1] = "ts-node";
        cmd[2] = "test/utils/ts/generateMsg.ts";
        cmd[3] = vm.toString(abi.encode(DOMAIN));
        bytes memory out = vm.ffi(cmd);

        ICheckpointManager.Validator[] memory validatorSetTmp;

        (validatorSetSize, validatorSetTmp, aggMessagePoints, hashes, bitmaps, aggVotingPowers) =
            abi.decode(out, (uint256, ICheckpointManager.Validator[], uint256[2][], bytes32[], bytes[], uint256[]));

        for (uint256 i = 0; i < validatorSetSize; i++) {
            validatorSet.push(validatorSetTmp[i]);
        }
        childChainId = 1;
    }
}

abstract contract InitializedCheckpointManager is UninitializedCheckpointManager {
    function setUp() public virtual override {
        super.setUp();
        checkpointManager.initialize(bls, bn256G2, childChainId);
        checkpointManager.setNewValidatorSet(validatorSet);
    }
}
