# EoracleConsumerExampleFeedAdapter

[Git Source](https://github.com/Eoracle/target-contracts/blob/ad9e9f7d406e96d8227780565e0953208bab6e55/src/examples/EoracleConsumerExampleFeedAdapter.sol)

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
