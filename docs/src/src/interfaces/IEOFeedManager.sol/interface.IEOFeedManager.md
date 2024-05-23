# IEOFeedManager

[Git Source](https://github.com/Eoracle/target-contracts/blob/2a1c0c442230a3038c84f19545812da920182a69/src/interfaces/IEOFeedManager.sol)

## Functions

### updatePriceFeed

```solidity
function updatePriceFeed(
    IEOFeedVerifier.LeafInput calldata input,
    IEOFeedVerifier.Checkpoint calldata checkpoint,
    uint256[2] calldata signature,
    bytes calldata bitmap
)
    external;
```

### updatePriceFeeds

```solidity
function updatePriceFeeds(
    IEOFeedVerifier.LeafInput[] calldata inputs,
    IEOFeedVerifier.Checkpoint calldata checkpoint,
    uint256[2] calldata signature,
    bytes calldata bitmap
)
    external;
```

### whitelistPublishers

```solidity
function whitelistPublishers(address[] memory publishers, bool[] memory isWhitelisted) external;
```

### getLatestPriceFeed

```solidity
function getLatestPriceFeed(uint16 feedId) external view returns (PriceFeed memory);
```

### getLatestPriceFeeds

```solidity
function getLatestPriceFeeds(uint16[] calldata feedIds) external view returns (PriceFeed[] memory);
```

### isWhitelistedPublisher

```solidity
function isWhitelistedPublisher(address publisher) external view returns (bool);
```

### isSupportedFeed

```solidity
function isSupportedFeed(uint16 feedId) external view returns (bool);
```

## Events

### RateUpdated

```solidity
event RateUpdated(uint16 feedId, uint256 rate, uint256 timestamp);
```

## Structs

### PriceFeed

```solidity
struct PriceFeed {
    uint256 value;
    uint256 timestamp;
}
```
