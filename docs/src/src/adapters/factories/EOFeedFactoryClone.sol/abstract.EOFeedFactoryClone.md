# EOFeedFactoryClone

[Git Source](https://github.com/Eoracle/target-contracts/blob/8a773595146b344dc5abd94aaf5ddfa445eed3c5/src/adapters/factories/EOFeedFactoryClone.sol)

**Inherits:** Initializable,
[EOFeedFactoryBase](/src/adapters/factories/EOFeedFactoryBase.sol/abstract.EOFeedFactoryBase.md)

## State Variables

### \_feedImplementation

```solidity
address private _feedImplementation;
```

## Functions

### getFeedAdapterImplementation

_Returns the address of the feedAdapter implementation._

```solidity
function getFeedAdapterImplementation() external view returns (address);
```

### \_\_EOFeedFactory_init

_Initializes the factory with the feedAdapter implementation._

```solidity
function __EOFeedFactory_init(address impl, address) internal override onlyInitializing;
```

### \_deployEOFeedAdapter

_Deploys a new feedAdapter instance via Clones library._

```solidity
function _deployEOFeedAdapter() internal override returns (address);
```
