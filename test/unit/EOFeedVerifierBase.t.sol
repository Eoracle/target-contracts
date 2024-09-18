// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Test } from "forge-std/Test.sol";
import { EOFeedVerifier } from "../../src/EOFeedVerifier.sol";
import { BLS } from "../../src/common/BLS.sol";
import { IEOFeedVerifier } from "../../src/interfaces/IEOFeedVerifier.sol";
import { Utils } from "../utils/Utils.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { BN256G2 } from "../../src/common/BN256G2.sol";
import { IBN256G2 } from "../../src/interfaces/IBN256G2.sol";

// solhint-disable max-states-count
// solhint-disable var-name-mixedcase

abstract contract UninitializedFeedVerifier is Test, Utils {
    struct DecodedData {
        IEOFeedVerifier.Validator[] validatorSet;
        uint256[] secrets;
        IEOFeedVerifier.LeafInput[] leafInputs1;
        bytes32 merkleRoot1;
        uint256 blockNumber1;
        bytes nonSignersBitmap1;
        uint256[2] sigG1_1;
        uint256[4] apkG2_1;
        IEOFeedVerifier.LeafInput[] leafInputs2;
        bytes32 merkleRoot2;
        uint256 blockNumber2;
        bytes nonSignersBitmap2;
        uint256[2] sigG1_2;
        uint256[4] apkG2_2;
        IEOFeedVerifier.LeafInput[] leafInputs3;
        bytes32 merkleRoot3;
        uint256 blockNumber3;
        bytes nonSignersBitmap3;
        uint256[2] sigG1_3;
        uint256[4] apkG2_3;
    }

    uint256 public eoracleChainId = 1;
    address public constant EOCHAIN_SENDER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    EOFeedVerifier public feedVerifier;
    BLS public bls;
    IBN256G2 public bn256G2;
    uint256 internal validatorSetSize;
    IEOFeedVerifier.Validator[] internal validatorSet;
    uint256[] internal secrets;
    IEOFeedVerifier.LeafInput[] internal leafInputs1;
    bytes32 internal merkleRoot1;
    uint256 internal blockNumber1;
    bytes internal nonSignersBitmap1;
    uint256[2] internal sigG1_1 = [uint256(0), uint256(0)];
    uint256[4] internal apkG2_1 = [uint256(0), uint256(0), uint256(0), uint256(0)];
    IEOFeedVerifier.LeafInput[] internal leafInputs2;
    bytes32 internal merkleRoot2;
    uint256 internal blockNumber2;
    bytes internal nonSignersBitmap2;
    uint256[2] internal sigG1_2 = [uint256(0), uint256(0)];
    uint256[4] internal apkG2_2 = [uint256(0), uint256(0), uint256(0), uint256(0)];
    IEOFeedVerifier.LeafInput[] internal leafInputs3;
    bytes32 internal merkleRoot3;
    uint256 internal blockNumber3;
    bytes internal nonSignersBitmap3;
    uint256[2] internal sigG1_3 = [uint256(0), uint256(0)];
    uint256[4] internal apkG2_3 = [uint256(0), uint256(0), uint256(0), uint256(0)];

    address public admin = makeAddr("admin");
    address public alice = makeAddr("Alice");
    address public bob = makeAddr("Bob");

    event ExitProcessed(uint256 indexed id, bool indexed success, bytes returnData);

    function setUp() public virtual {
        admin = makeAddr("admin");
        alice = makeAddr("Alice");
        bob = makeAddr("Bob");

        DecodedData memory decoded = abi.decode(getData(), (DecodedData));

        validatorSetSize = decoded.validatorSet.length;
        for (uint256 i = 0; i < validatorSetSize; i++) {
            validatorSet.push(decoded.validatorSet[i]);
        }
        for (uint256 i = 0; i < decoded.secrets.length; i++) {
            secrets.push(decoded.secrets[i]);
        }
        for (uint256 i = 0; i < decoded.leafInputs1.length; i++) {
            leafInputs1.push(decoded.leafInputs1[i]);
        }
        for (uint256 i = 0; i < decoded.leafInputs2.length; i++) {
            leafInputs2.push(decoded.leafInputs2[i]);
        }
        for (uint256 i = 0; i < decoded.leafInputs3.length; i++) {
            leafInputs3.push(decoded.leafInputs3[i]);
        }

        // full signature - 4/4 voters
        merkleRoot1 = decoded.merkleRoot1;
        blockNumber1 = decoded.blockNumber1;
        nonSignersBitmap1 = decoded.nonSignersBitmap1;
        sigG1_1 = decoded.sigG1_1;
        apkG2_1 = decoded.apkG2_1;

        // partial signature - 3/4 voters
        merkleRoot2 = decoded.merkleRoot2;
        blockNumber2 = decoded.blockNumber2;
        nonSignersBitmap2 = decoded.nonSignersBitmap2;
        sigG1_2 = decoded.sigG1_2;
        apkG2_2 = decoded.apkG2_2;

        // partial signature - 1/4 voters
        merkleRoot3 = decoded.merkleRoot3;
        blockNumber3 = decoded.blockNumber3;
        nonSignersBitmap3 = decoded.nonSignersBitmap3;
        sigG1_3 = decoded.sigG1_3;
        apkG2_3 = decoded.apkG2_3;

        bls = new BLS();
        _setBN256G2();
    }

    function _setBN256G2() internal virtual {
        bn256G2 = new BN256G2();
    }

    function _getDefaultInputLeaf() internal view returns (IEOFeedVerifier.LeafInput memory) {
        return leafInputs1[0];
    }

    function _getDefaultInput() internal view returns (IEOFeedVerifier.LeafInput[] memory) {
        IEOFeedVerifier.LeafInput[] memory _input = new IEOFeedVerifier.LeafInput[](leafInputs1.length);
        for (uint256 i = 0; i < leafInputs1.length; i++) {
            _input[i] = leafInputs1[i];
        }
        return _input;
    }

    function _getNotEnoughVotingPowerInput() internal view returns (IEOFeedVerifier.LeafInput[] memory) {
        IEOFeedVerifier.LeafInput[] memory _input = new IEOFeedVerifier.LeafInput[](leafInputs3.length);
        for (uint256 i = 0; i < leafInputs3.length; i++) {
            _input[i] = leafInputs3[i];
        }
        return _input;
    }

    function _getDefaultVerificationParams() internal view returns (IEOFeedVerifier.VerificationParams memory) {
        return IEOFeedVerifier.VerificationParams({
            eventRoot: merkleRoot1,
            blockNumber: blockNumber1,
            signature: sigG1_1,
            apkG2: apkG2_1,
            nonSignersBitmap: nonSignersBitmap1
        });
    }

    function _getNotEnoughVotingPowerVerificationParams()
        internal
        view
        returns (IEOFeedVerifier.VerificationParams memory)
    {
        return IEOFeedVerifier.VerificationParams({
            eventRoot: merkleRoot3,
            blockNumber: blockNumber3,
            signature: sigG1_3,
            apkG2: apkG2_3,
            nonSignersBitmap: nonSignersBitmap3
        });
    }

    function getData() private returns (bytes memory) {
        feedVerifier = EOFeedVerifier(Upgrades.deployTransparentProxy("EOFeedVerifier.sol", admin, ""));
        string[] memory cmd = new string[](3);
        cmd[0] = "npx";
        cmd[1] = "ts-node";
        cmd[2] = "test/utils/ts/createVerifyableData.ts";
        return vm.ffi(cmd);
    }
}

abstract contract InitializedFeedVerifier is UninitializedFeedVerifier {
    function setUp() public virtual override {
        super.setUp();
        address[] memory allowedSenders = new address[](1);
        allowedSenders[0] = EOCHAIN_SENDER;

        feedVerifier.initialize(address(this), bls, bn256G2, eoracleChainId, allowedSenders);
        feedVerifier.setNewValidatorSet(validatorSet);
        feedVerifier.setFeedManager(address(this));
    }
}
