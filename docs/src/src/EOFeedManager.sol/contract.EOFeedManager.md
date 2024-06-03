# EOFeedManager

[Git Source](https://github.com/Eoracle/target-contracts/blob/de89fc9e9bc7c046937883aa064d90812f1542cc/src/EOFeedManager.sol)

**Inherits:** Initializable, OwnableUpgradeable,
[IEOFeedManager](/src/interfaces/IEOFeedManager.sol/interface.IEOFeedManager.md)

The EOFeedManager contract is responsible for receiving feed updates from whitelisted publishers. These updates are
verified using the logic in the EOFeedVerifier. Upon successful verification, the feed data is stored in the
EOFeedManager and made available for other smart contracts to read. Only supported feed IDs can be published to the feed
manager.

## State Variables

### \_priceFeeds

_Map of feed id to price feed (feed id => PriceFeed)_

```solidity
mapping(uint16 => PriceFeed) internal _priceFeeds;
```

### \_whitelistedPublishers

_Map of whitelisted publishers (publisher => is whitelisted)_

```solidity
mapping(address => bool) internal _whitelistedPublishers;
```

### \_supportedFeedIds

_Map of supported feeds, (feed id => is supported)_

```solidity
mapping(uint16 => bool) internal _supportedFeedIds;
```

### \_feedVerifier

_feed verifier contract_

```solidity
IEOFeedVerifier internal _feedVerifier;
```

## Functions

### onlyWhitelisted

_Allows only whitelisted publishers to call the function_

```solidity
modifier onlyWhitelisted();
```

### onlyNonZeroAddress

_Allows only non-zero addresses_

```solidity
modifier onlyNonZeroAddress(address addr);
```

### initialize

Initialize the contract with the feed verifier address

_The feed verifier contract must be deployed first_

```solidity
function initialize(address feedVerifier, address owner) external onlyNonZeroAddress(feedVerifier) initializer;
```

**Parameters**

| Name           | Type      | Description                           |
| -------------- | --------- | ------------------------------------- |
| `feedVerifier` | `address` | Address of the feed verifier contract |
| `owner`        | `address` | Owner of the contract                 |

### setFeedVerifier

Set the feed verifier contract address

```solidity
function setFeedVerifier(address feedVerifier) external onlyOwner onlyNonZeroAddress(feedVerifier);
```

**Parameters**

| Name           | Type      | Description                           |
| -------------- | --------- | ------------------------------------- |
| `feedVerifier` | `address` | Address of the feed verifier contract |

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

Process the verified rate, check and save it

```solidity
function _processVerifiedRate(bytes memory data, uint256 blockNumber) internal;
```

**Parameters**

| Name          | Type      | Description                                                                      |
| ------------- | --------- | -------------------------------------------------------------------------------- |
| `data`        | `bytes`   | Verified rate data, abi encoded (uint16 feedId, uint256 rate, uint256 timestamp) |
| `blockNumber` | `uint256` | eoracle chain block number                                                       |

### \_getLatestPriceFeed

Get the latest price feed

```solidity
function _getLatestPriceFeed(uint16 feedId) internal view returns (PriceFeed memory);
```

**Parameters**

| Name     | Type     | Description |
| -------- | -------- | ----------- |
| `feedId` | `uint16` | Feed id     |

**Returns**

| Name     | Type        | Description      |
| -------- | ----------- | ---------------- |
| `<none>` | `PriceFeed` | PriceFeed struct |
