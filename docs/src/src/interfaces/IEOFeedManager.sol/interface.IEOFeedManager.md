# IEOFeedManager

[Git Source](https://github.com/Eoracle/target-contracts/blob/ad9e9f7d406e96d8227780565e0953208bab6e55/src/interfaces/IEOFeedManager.sol)

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
