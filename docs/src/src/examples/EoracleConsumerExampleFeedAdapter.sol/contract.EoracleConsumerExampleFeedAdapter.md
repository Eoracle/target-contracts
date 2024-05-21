# EoracleConsumerExampleFeedAdapter

[Git Source](https://github.com/Eoracle/target-contracts/blob/f4fda3a61e4cccb09ed94cf04c4ed0f0b162d9e8/src/examples/EoracleConsumerExampleFeedAdapter.sol)

## State Variables

### \_feedAdapter

```solidity
IEOFeedAdapter private _feedAdapter;
```

## Functions

### constructor

```solidity
constructor(address feedAdapter);
```

### setFeed

```solidity
function setFeed(address feedAdapter) external;
```

### getFeed

```solidity
function getFeed() external view returns (IEOFeedAdapter);
```

### getPrice

```solidity
function getPrice() external view returns (int256 answer);
```
