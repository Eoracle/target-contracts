# IEOFeedRegistryAdapter

[Git Source](https://github.com/Eoracle/target-contracts/blob/de89fc9e9bc7c046937883aa064d90812f1542cc/src/adapters/interfaces/IEOFeedRegistryAdapter.sol)

Interface for the FeedManager contract.

_Simplified version of FeedRegistryInterface from CL._

## Functions

### decimals

```solidity
function decimals(address base, address quote) external view returns (uint8);
```

### description

```solidity
function description(address base, address quote) external view returns (string memory);
```

### version

```solidity
function version(address base, address quote) external view returns (uint256);
```

### latestRoundData

```solidity
function latestRoundData(
    address base,
    address quote
)
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
```

### getRoundData

```solidity
function getRoundData(
    address base,
    address quote,
    uint80 _roundId
)
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
```

### latestAnswer

```solidity
function latestAnswer(address base, address quote) external view returns (int256 answer);
```

### latestTimestamp

```solidity
function latestTimestamp(address base, address quote) external view returns (uint256 timestamp);
```

### latestRound

```solidity
function latestRound(address base, address quote) external view returns (uint256 roundId);
```

### getAnswer

```solidity
function getAnswer(address base, address quote, uint256 roundId) external view returns (int256 answer);
```

### getTimestamp

```solidity
function getTimestamp(address base, address quote, uint256 roundId) external view returns (uint256 timestamp);
```

### getFeed

```solidity
function getFeed(address base, address quote) external view returns (IEOFeedAdapter feedAdapter);
```

### isFeedEnabled

```solidity
function isFeedEnabled(address feedAdapter) external view returns (bool);
```

### getRoundFeed

```solidity
function getRoundFeed(address base, address quote, uint80 roundId) external view returns (IEOFeedAdapter feedAdapter);
```
