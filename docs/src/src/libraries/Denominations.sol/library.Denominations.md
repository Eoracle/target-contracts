# Denominations

[Git Source](https://github.com/Eoracle/target-contracts/blob/de89fc9e9bc7c046937883aa064d90812f1542cc/src/libraries/Denominations.sol)

## State Variables

### ETH

```solidity
address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
```

### BTC

```solidity
address public constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;
```

### DOGE

```solidity
address public constant DOGE = 0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd;
```

### USD

```solidity
address public constant USD = address(840);
```

### GBP

```solidity
address public constant GBP = address(826);
```

### EUR

```solidity
address public constant EUR = address(978);
```

### JPY

```solidity
address public constant JPY = address(392);
```

### KRW

```solidity
address public constant KRW = address(410);
```

### CNY

```solidity
address public constant CNY = address(156);
```

### AUD

```solidity
address public constant AUD = address(36);
```

### CAD

```solidity
address public constant CAD = address(124);
```

### CHF

```solidity
address public constant CHF = address(756);
```

### ARS

```solidity
address public constant ARS = address(32);
```

### PHP

```solidity
address public constant PHP = address(608);
```

### NZD

```solidity
address public constant NZD = address(554);
```

### SGD

```solidity
address public constant SGD = address(702);
```

### NGN

```solidity
address public constant NGN = address(566);
```

### ZAR

```solidity
address public constant ZAR = address(710);
```

### RUB

```solidity
address public constant RUB = address(643);
```

### INR

```solidity
address public constant INR = address(356);
```

### BRL

```solidity
address public constant BRL = address(986);
```

## Functions

### isETH

```solidity
function isETH(address token) internal pure returns (bool);
```
