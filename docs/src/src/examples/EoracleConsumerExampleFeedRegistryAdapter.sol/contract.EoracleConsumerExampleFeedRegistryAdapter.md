# EoracleConsumerExampleFeedRegistryAdapter

[Git Source](https://github.com/Eoracle/target-contracts/blob/ad9e9f7d406e96d8227780565e0953208bab6e55/src/examples/EoracleConsumerExampleFeedRegistryAdapter.sol)

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
function getEthUsdPrice() public view returns (int256);
```

### getPrice

```solidity
function getPrice(address base, address quote) public view returns (int256);
```
