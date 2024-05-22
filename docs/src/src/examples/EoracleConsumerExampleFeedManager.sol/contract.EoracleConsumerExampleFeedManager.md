# EoracleConsumerExampleFeedManager

[Git Source](https://github.com/Eoracle/target-contracts/blob/ad9e9f7d406e96d8227780565e0953208bab6e55/src/examples/EoracleConsumerExampleFeedManager.sol)

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
