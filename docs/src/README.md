# Eoracle

Repository for the Eoracle target smart contracts

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

### Clean

Delete the build artifacts and cache directories:

```sh
$ forge clean
```

### Compile

Compile the contracts:

```sh
$ forge build
```

### Coverage

Get a test coverage report:

```sh
$ forge coverage
```

### Gas Usage

Get a gas report:

```sh
$ npm run gas-snapshot
```

### Lint

Lint the contracts:

```sh
$ npm run lint
```

### Compile

```sh
$ npm run build
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

Generate test coverage and output result to the terminal:

```sh
$ npm run test:coverage
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
  - **quote** - address of the qoute token (erc-20 address or address from [Denominations](src/libraries/Denominations.sol/library.Denominations.md)
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

#### Deploy examples

Deploy library which can be used by customers
 
```sh
$ npm run deploy:lib
```

Deploy example of interaction with EOFeedManager directly
 
```sh
$ npm run deploy:consumer:feedManager
```

Deploy example of interaction with EOFeedRegistryAdapter
 
```sh
$ npm run deploy:consumer:feedRegistryAdapter
```

Deploy example of interaction with EOFeedAdapter
 
```sh
$ npm run deploy:consumer:feedAdapter
```

## License

This project is licensed under MIT.
