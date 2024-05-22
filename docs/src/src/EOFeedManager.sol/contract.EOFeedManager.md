# EOFeedManager

[Git Source](https://github.com/Eoracle/target-contracts/blob/ad9e9f7d406e96d8227780565e0953208bab6e55/src/EOFeedManager.sol)

**Inherits:** Initializable, OwnableUpgradeable,
[IEOFeedManager](/src/interfaces/IEOFeedManager.sol/interface.IEOFeedManager.md)

## State Variables

### \_priceFeeds

```solidity
mapping(uint16 => PriceFeed) internal _priceFeeds;
```

### \_whitelistedPublishers

```solidity
mapping(address => bool) internal _whitelistedPublishers;
```

### \_supportedFeedIds

```solidity
mapping(uint16 => bool) internal _supportedFeedIds;
```

### \_feedVerifier

```solidity
IEOFeedVerifier internal _feedVerifier;
```

### \_lastProcessedBlockNumber

```solidity
uint256 internal _lastProcessedBlockNumber;
```

## Functions

### onlyWhitelisted

```solidity
modifier onlyWhitelisted();
```

### initialize

Initialize the contract with the feed verifier address

_The feed verifier contract must be deployed first_

```solidity
function initialize(IEOFeedVerifier feedVerifier, address owner) external initializer;
```

**Parameters**

| Name           | Type              | Description                           |
| -------------- | ----------------- | ------------------------------------- |
| `feedVerifier` | `IEOFeedVerifier` | Address of the feed verifier contract |
| `owner`        | `address`         | Owner of the contract                 |

### setSupportedFeeds

Set the supported feeds

```solidity
function setSupportedFeeds(uint16[] calldata feedIds, bool[] calldata isSupported) external onlyOwner;
```

**Parameters**

| Name          | Type       | Description                                                |
| ------------- | ---------- | ---------------------------------------------------------- |
| `feedIds`     | `uint16[]` | Array of feed ids                                          |
| `isSupported` | `bool[]`   | Array of booleans indicating whether the feed is supported |

### whitelistPublishers

Set the whitelisted publishers

```solidity
function whitelistPublishers(address[] memory publishers, bool[] memory isWhitelisted) external onlyOwner;
```

**Parameters**

| Name            | Type        | Description                                                       |
| --------------- | ----------- | ----------------------------------------------------------------- |
| `publishers`    | `address[]` | Array of publisher addresses                                      |
| `isWhitelisted` | `bool[]`    | Array of booleans indicating whether the publisher is whitelisted |

### updatePriceFeed

Update the price for a feed

```solidity
function updatePriceFeed(
    IEOFeedVerifier.LeafInput memory input,
    IEOFeedVerifier.Checkpoint calldata checkpoint,
    uint256[2] calldata signature,
    bytes calldata bitmap
)
    external
    onlyWhitelisted;
```

**Parameters**

| Name         | Type                         | Description                                        |
| ------------ | ---------------------------- | -------------------------------------------------- |
| `input`      | `IEOFeedVerifier.LeafInput`  | A leaf to prove the price feeds                    |
| `checkpoint` | `IEOFeedVerifier.Checkpoint` | Checkpoint data                                    |
| `signature`  | `uint256[2]`                 | Aggregated signature of the checkpoint             |
| `bitmap`     | `bytes`                      | Bitmap of the validators who signed the checkpoint |

### updatePriceFeeds

Update the price for multiple feeds

```solidity
function updatePriceFeeds(
    IEOFeedVerifier.LeafInput[] calldata inputs,
    IEOFeedVerifier.Checkpoint calldata checkpoint,
    uint256[2] calldata signature,
    bytes calldata bitmap
)
    external
    onlyWhitelisted;
```

**Parameters**

| Name         | Type                          | Description                                        |
| ------------ | ----------------------------- | -------------------------------------------------- |
| `inputs`     | `IEOFeedVerifier.LeafInput[]` | Array of leafs to prove the price feeds            |
| `checkpoint` | `IEOFeedVerifier.Checkpoint`  | Checkpoint data                                    |
| `signature`  | `uint256[2]`                  | Aggregated signature of the checkpoint             |
| `bitmap`     | `bytes`                       | Bitmap of the validators who signed the checkpoint |

### getLatestPriceFeed

Get the latest price for a feed

```solidity
function getLatestPriceFeed(uint16 feedId) external view returns (PriceFeed memory);
```

**Parameters**

| Name     | Type     | Description |
| -------- | -------- | ----------- |
| `feedId` | `uint16` | Feed id     |

**Returns**

| Name     | Type        | Description      |
| -------- | ----------- | ---------------- |
| `<none>` | `PriceFeed` | PriceFeed struct |

### getLatestPriceFeeds

Get the latest price feeds for multiple feeds

```solidity
function getLatestPriceFeeds(uint16[] calldata feedIds) external view returns (PriceFeed[] memory);
```

**Parameters**

| Name      | Type       | Description       |
| --------- | ---------- | ----------------- |
| `feedIds` | `uint16[]` | Array of feed ids |

**Returns**

| Name     | Type          | Description                 |
| -------- | ------------- | --------------------------- |
| `<none>` | `PriceFeed[]` | Array of price feed structs |

### isWhitelistedPublisher

Check if a publisher is whitelisted

```solidity
function isWhitelistedPublisher(address publisher) external view returns (bool);
```

**Parameters**

| Name        | Type      | Description              |
| ----------- | --------- | ------------------------ |
| `publisher` | `address` | Address of the publisher |

**Returns**

| Name     | Type   | Description                                             |
| -------- | ------ | ------------------------------------------------------- |
| `<none>` | `bool` | Boolean indicating whether the publisher is whitelisted |

### isSupportedFeed

Check if a feed is supported

```solidity
function isSupportedFeed(uint16 feedId) external view returns (bool);
```

**Parameters**

| Name     | Type     | Description      |
| -------- | -------- | ---------------- |
| `feedId` | `uint16` | feed Id to check |

**Returns**

| Name     | Type   | Description                                      |
| -------- | ------ | ------------------------------------------------ |
| `<none>` | `bool` | Boolean indicating whether the feed is supported |

### getFeedVerifier

Get the feed verifier contract address

```solidity
function getFeedVerifier() external view returns (IEOFeedVerifier);
```

**Returns**

| Name     | Type              | Description                           |
| -------- | ----------------- | ------------------------------------- |
| `<none>` | `IEOFeedVerifier` | Address of the feed verifier contract |

### \_processVerifiedRate

```solidity
function _processVerifiedRate(bytes memory data) internal;
```

### \_getLatestPriceFeed

```solidity
function _getLatestPriceFeed(uint16 feedId) internal view returns (PriceFeed memory);
```
