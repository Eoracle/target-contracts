// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IEOFeedRegistryAdapter } from "../adapters/interfaces/IEOFeedRegistryAdapter.sol";
import { Denominations } from "../libraries/Denominations.sol";

contract EoracleConsumerExampleFeedRegistryAdapter {
    // solhint-disable-next-line var-name-mixedcase
    IEOFeedRegistryAdapter private _feedRegistryAdapter;

    constructor(address feedRegistryAdapter) {
        _feedRegistryAdapter = IEOFeedRegistryAdapter(feedRegistryAdapter);
    }

    function setFeedRegistryAdapter(address feedRegistryAdapter) external {
        _feedRegistryAdapter = IEOFeedRegistryAdapter(feedRegistryAdapter);
    }

    function getFeedRegistryAdapter() external view returns (IEOFeedRegistryAdapter) {
        return _feedRegistryAdapter;
    }

    function getEthUsdPrice() external view returns (int256) {
        return _feedRegistryAdapter.latestAnswer(Denominations.ETH, Denominations.USD);
    }

    function getPrice(address base, address quote) external view returns (int256) {
        return _feedRegistryAdapter.latestAnswer(base, quote);
    }
}
