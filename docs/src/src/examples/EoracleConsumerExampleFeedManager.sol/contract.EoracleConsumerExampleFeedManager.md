# EoracleConsumerExampleFeedManager

[Git Source](https://github.com/Eoracle/target-contracts/blob/326365dd645fcf8a14532250ed14441e57e11e4f/src/examples/EoracleConsumerExampleFeedManager.sol)

## State Variables

### \_feedManager

```solidity
IEOFeedManager private _feedManager;
```

## Functions

### constructor

```solidity
constructor(address feedManager);
```

### setFeedManager

```solidity
function setFeedManager(address feedManager) external;
```

### getFeedManager

```solidity
function getFeedManager() external view returns (IEOFeedManager);
```

### getPrice

```solidity
function getPrice(uint16 feedId) external view returns (IEOFeedManager.PriceFeed memory);
```

### getPrices

```solidity
function getPrices(uint16[] calldata feedIds) external view returns (IEOFeedManager.PriceFeed[] memory);
```
