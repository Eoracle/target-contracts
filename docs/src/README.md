# Eoracle

eoracle is a programmable data layer that extends Ethereum Proof of Stake to connect smart contracts with real-world data.
To get a basic understand of eoracle, checkout our [documentation](https://eoracle.gitbook.io/eoracle).

## Overview

The target contracts consists of two primary smart contracts: EOFeedManager and EOFeedVerifier. The EOFeedManager receives feed updates from whitelisted publishers, verifies them using EOFeedVerifier, and stores the verified data for access by other smart contracts. The EOFeedVerifier handles the verification process, ensuring the integrity and authenticity of the price feed updates.

## EOFeedManager

The EOFeedManager contract is responsible for receiving feed updates from whitelisted publishers. These updates are verified using the logic in the EOFeedVerifier. Upon successful verification, the feed data is stored in the EOFeedManager and made available for other smart contracts to read. Only supported feed IDs can be published to the feed manager.

## EOFeedVerifier

The EOFeedVerifier contract handles the verification of update payloads. The payload includes a Merkle root signed by eoracle validators and a Merkle path to the leaf containing the data. The verifier stores the current validator set in its storage and ensures that the Merkle root is signed by a subset of this validator set with sufficient voting power.

## Documentation

- [EOFeedManager](docs/src/src/EOFeedManager.sol/contract.EOFeedManager.md)
- [EOFeedVerifier](docs/src/src/EOFeedVerifier.sol/contract.EOFeedVerifier.md)

[Full list](docs/src/SUMMARY.md)

## Usage

This is a list of the most frequently needed commands.

### Build

Build the contracts:

```sh
$ forge build
```

### Coverage

Get a test coverage report:

```sh
$ forge coverage
```

### Test

Run the unit tests:

```sh
$ npm run test
```

Run the integration tests:

```sh
$ npm run test:integration
```

Generate test coverage with lcov report

```sh
$ npm run test:coverage:report
```

### Configuration file

Configuration file is located by path `script/config/{targetChainId}/{eoracleChainId}/targetContractSetConfig.json`

#### Configuration attributes

- **usePrecompiledModexp** - boolean, should be set to _true_ if deployment should be done using precompiled contract, _false_ - if the solidity
  version of modexp needed to be used (for the chain that don't support precompiled modexp)

- **proxyAdminOwner** - the owner of ProxyAdmin smart contracts

- **targetContractsOwner** - the owner of core contracts

- **eoracleChainId** - id of the child chain

- **targetChainId** - id of the target chain

- **publishers** - array of publisher addresses

- **supportedFeedIds** - array of supported feed ids

- **supportedFeedsData** - array with data of the feeds

  - **base** - address of the base token (erc-20 address or address from [Denominations](src/libraries/Denominations.sol/library.Denominations.md))
  - **quote** - address of the quote token (erc-20 address or address from [Denominations](src/libraries/Denominations.sol/library.Denominations.md)
  - **decimals** - rate decimals for the feed
  - **description** - feed description
  - **feedId** - id of the feed

### Deploy 

For all deploy scripts to work, you need to set [configuration file](#configuration-file) and .env file with the following environment variables 
- PRIVATE_KEY - private key of deployer 
- OWNER_PRIVATE_KEY - private key of the contracts owner (needed for Setup core contracts and Deploy feeds adapters)
- RPC_URL - rpc url of the target chain
- ETHERSCAN_API_KEY - key for verification
- EORACLE_CHAIN_ID - id of the child chain

#### Deploy core contracts

Deploy core contracts EOFeedManager and EOFeedVerifier

```sh
$ npm run deploy
```

#### Setup core contracts

Run the setup for core contracts (calls `setSupportedFeeds` and `whitelistPublishers` passing **supportedFeedIds**  and **publishers** from configuration file)

```sh
$ npm run deploy:setup
```
#### Deploy registry adapter

Deploy the adapter (EOFeedRegistryAdapter)

```sh
$ npm run deploy:adapters
```

#### Deploy feeds adapters

Deploy the adapter for configured feeds (deploy EOFeedAdapter per each feed specified in **supportedFeedsData** in configuration file)

```sh
$ npm run deploy:feeds
```

## License

This project is licensed under MIT.
