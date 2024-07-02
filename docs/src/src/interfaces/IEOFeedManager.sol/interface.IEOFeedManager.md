# IEOFeedManager

[Git Source](https://github.com/Eoracle/target-contracts/blob/de89fc9e9bc7c046937883aa064d90812f1542cc/src/interfaces/IEOFeedManager.sol)

## Functions

### updatePriceFeed

Update the price for a feed

```solidity
function updatePriceFeed(
    IEOFeedVerifier.LeafInput calldata input,
    IEOFeedVerifier.Checkpoint calldata checkpoint,
    uint256[2] calldata signature,
    bytes calldata bitmap
)
    external;
```

**Parameters**

| Name         | Type                         | Description                                                                |
| ------------ | ---------------------------- | -------------------------------------------------------------------------- |
| `input`      | `IEOFeedVerifier.LeafInput`  | A merkle leaf containing price data and its merkle proof                   |
| `checkpoint` | `IEOFeedVerifier.Checkpoint` | Checkpoint data containing eoracle chain metadata and the data merkle root |
| `signature`  | `uint256[2]`                 | Aggregated signature of the checkpoint                                     |
| `bitmap`     | `bytes`                      | Bitmap of the validators who signed the checkpoint                         |

### updatePriceFeeds

Update the price for multiple feeds

```solidity
function updatePriceFeeds(
    IEOFeedVerifier.LeafInput[] calldata inputs,
    IEOFeedVerifier.Checkpoint calldata checkpoint,
    uint256[2] calldata signature,
    bytes calldata bitmap
)
    external;
```

**Parameters**

| Name         | Type                          | Description                                        |
| ------------ | ----------------------------- | -------------------------------------------------- |
| `inputs`     | `IEOFeedVerifier.LeafInput[]` | Array of leafs to prove the price feeds            |
| `checkpoint` | `IEOFeedVerifier.Checkpoint`  | Checkpoint data                                    |
| `signature`  | `uint256[2]`                  | Aggregated signature of the checkpoint             |
| `bitmap`     | `bytes`                       | Bitmap of the validators who signed the checkpoint |

### whitelistPublishers

Set the whitelisted publishers

```solidity
function whitelistPublishers(address[] memory publishers, bool[] memory isWhitelisted) external;
```

**Parameters**

| Name            | Type        | Description                                                       |
| --------------- | ----------- | ----------------------------------------------------------------- |
| `publishers`    | `address[]` | Array of publisher addresses                                      |
| `isWhitelisted` | `bool[]`    | Array of booleans indicating whether the publisher is whitelisted |

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

| Name     | Type          | Description                |
| -------- | ------------- | -------------------------- |
| `<none>` | `PriceFeed[]` | Array of PriceFeed structs |

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

## Events

### RateUpdated

_Event emitted when a price feed is updated_

```solidity
event RateUpdated(uint16 indexed feedId, uint256 rate, uint256 timestamp);
```

**Parameters**

| Name        | Type      | Description          |
| ----------- | --------- | -------------------- |
| `feedId`    | `uint16`  | Feed id              |
| `rate`      | `uint256` | Price feed value     |
| `timestamp` | `uint256` | Price feed timestamp |

## Structs

### PriceFeed

_Price feed structure_

```solidity
struct PriceFeed {
    uint256 value;
    uint256 timestamp;
    uint256 eoracleBlockNumber;
}
```

**Properties**

| Name                 | Type      | Description                                                                                |
| -------------------- | --------- | ------------------------------------------------------------------------------------------ |
| `value`              | `uint256` | Price feed value                                                                           |
| `timestamp`          | `uint256` | Price feed timestamp (block timestamp in eoracle chain when price feed rate is aggregated) |
| `eoracleBlockNumber` | `uint256` | eoracle block number                                                                       |
