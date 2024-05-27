# EOFeedFactoryBeacon

[Git Source](https://github.com/Eoracle/target-contracts/blob/1999827c161f91e9bc99ac290d34e4d278bf02c5/src/adapters/factories/EOFeedFactoryBeacon.sol)

**Inherits:** Initializable,
[EOFeedFactoryBase](/src/adapters/factories/EOFeedFactoryBase.sol/abstract.EOFeedFactoryBase.md)

## State Variables

### \_beacon

```solidity
address private _beacon;
```

## Functions

### getBeacon

_Returns the address of the beacon._

```solidity
function getBeacon() external view returns (address);
```

### \_\_EOFeedFactory_init

_Initializes the factory with the feedAdapter implementation._

```solidity
function __EOFeedFactory_init(address impl, address initialOwner) internal override onlyInitializing;
```

### \_deployEOFeedAdapter

_Deploys a new feedAdapter instance via Beacon proxy._

```solidity
function _deployEOFeedAdapter() internal override returns (address);
```
