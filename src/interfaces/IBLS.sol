// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IBLS {
    /**
     * @notice hashes an arbitrary message to a point on the curve
     * @dev Fouque-Tibouchi Hash to Curve
     * @param domain domain separator for the hash
     * @param message the message to map
     * @return uint256[2] (x,y) point on the curve that the message maps to
     */
    function hashToPoint(bytes32 domain, bytes memory message) external view returns (uint256[2] memory);

    /**
     * @notice verifies a single signature
     * @param signature 64-byte G1 group element (small sig)
     * @param pubkey 128-byte G2 group element (big pubkey)
     * @param message message signed to produce signature
     * @return bool sig verification
     * @return bool indicating call success
     */
    function verifySignature(
        uint256[2] calldata signature,
        uint256[4] calldata pubkey,
        uint256[2] calldata message
    )
        external
        view
        returns (bool, bool);

    /**
     * @notice verifies a single signature and the veracity of the apk
     * @param pubkey 64-byte G1 group element (small pubkey) - the claimed G1 pubkey
     * @param signature 64-byte G1 group element (small sig)
     * @param message hash 64-byte message signed to produce signature
     * @param pubkeyG2 128-byte G2 group element (big apk) - the provided G2 pubkey
     * @return bool sig verification
     * @return bool indicating call success
     */
    function verifySignatureAndVeracity(
        uint256[2] calldata pubkey,
        uint256[2] calldata signature,
        uint256[2] calldata message,
        uint256[4] calldata pubkeyG2
    )
        external
        view
        returns (bool, bool);

    function ecadd(uint256[2] calldata a, uint256[2] calldata b) external view returns (uint256[2] memory);
    function ecmul(uint256[2] calldata p, uint256 s) external view returns (uint256[2] memory);
    function neg(uint256[2] calldata a) external pure returns (uint256[2] memory);
}
