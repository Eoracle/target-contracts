# EoracleConsumerExampleFeedAdapter

[Git Source](https://github.com/Eoracle/target-contracts/blob/6bb0b8b006e19f44d4eb44f1e9a8043f769d4816/src/examples/EoracleConsumerExampleFeedAdapter.sol)

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
