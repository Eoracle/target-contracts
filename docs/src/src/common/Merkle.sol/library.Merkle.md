# Merkle

[Git Source](https://github.com/Eoracle/target-contracts/blob/de89fc9e9bc7c046937883aa064d90812f1542cc/src/common/Merkle.sol)

**Author:** QEDK

Gas optimized verification of proof of inclusion for a leaf in an ordered Merkle tree

## Functions

### checkMembership

checks membership of a leaf in a merkle tree

```solidity
function checkMembership(
    bytes32 leaf,
    uint256 index,
    bytes32 rootHash,
    bytes32[] calldata proof
)
    internal
    pure
    returns (bool isMember);
```

**Parameters**

| Name       | Type        | Description                                                   |
| ---------- | ----------- | ------------------------------------------------------------- |
| `leaf`     | `bytes32`   | keccak256 hash to check the membership of                     |
| `index`    | `uint256`   | position of the hash in the tree                              |
| `rootHash` | `bytes32`   | root hash of the merkle tree                                  |
| `proof`    | `bytes32[]` | an array of hashes needed to prove the membership of the leaf |

**Returns**

| Name       | Type   | Description                                                |
| ---------- | ------ | ---------------------------------------------------------- |
| `isMember` | `bool` | boolean value indicating if the leaf is in the tree or not |
