# EoracleConsumerExampleFeedRegistryAdapter

[Git Source](https://github.com/Eoracle/target-contracts/blob/1999827c161f91e9bc99ac290d34e4d278bf02c5/src/examples/EoracleConsumerExampleFeedRegistryAdapter.sol)

## State Variables

### \_feedRegistryAdapter

```solidity
IEOFeedRegistryAdapter private _feedRegistryAdapter;
```

## Functions

### constructor

```solidity
constructor(address feedRegistryAdapter);
```

### setFeedRegistryAdapter

```solidity
function setFeedRegistryAdapter(address feedRegistryAdapter) external;
```

### getFeedRegistryAdapter

```solidity
function getFeedRegistryAdapter() external view returns (IEOFeedRegistryAdapter);
```

### getEthUsdPrice

```solidity
function getEthUsdPrice() external view returns (int256);
```

### getPrice

```solidity
function getPrice(address base, address quote) external view returns (int256);
```
