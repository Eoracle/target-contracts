// Sources flattened with hardhat v2.19.1 https://hardhat.org

// SPDX-License-Identifier: MIT

// File lib/core-contracts/contracts/interfaces/common/IBLS.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity 0.8.20;

interface IBLS {
    function verifySingle(
        uint256[2] calldata signature,
        uint256[4] calldata pubkey,
        uint256[2] calldata message
    )
        external
        view
        returns (bool, bool);

    function hashToPoint(bytes32 domain, bytes memory message) external view returns (uint256[2] memory);

    function mapToPoint(uint256 _x) external pure returns (uint256[2] memory p);
}

contract MockBLS is IBLS {
    function verifySingle(
        uint256[2] calldata,
        uint256[4] calldata,
        uint256[2] calldata
    )
        external
        pure
        returns (bool, bool)
    {
        return (true, true);
    }

    function mapToPoint(uint256) external pure returns (uint256[2] memory p) {
        p[0] = 0;
        p[1] = 0;
    }

    function hashToPoint(bytes32, bytes memory) external pure returns (uint256[2] memory p) {
        p[0] = 0;
        p[1] = 0;
    }
}
