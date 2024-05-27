// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IEOFeedAdapter } from "../adapters/interfaces/IEOFeedAdapter.sol";

contract EoracleConsumerExampleFeedAdapter {
    // solhint-disable-next-line var-name-mixedcase
    IEOFeedAdapter private _feedAdapter;

    constructor(address feedAdapter) {
        _feedAdapter = IEOFeedAdapter(feedAdapter);
    }

    function setFeed(address feedAdapter) external {
        _feedAdapter = IEOFeedAdapter(feedAdapter);
    }

    function getFeed() external view returns (IEOFeedAdapter) {
        return _feedAdapter;
    }

    function getPrice() external view returns (int256 answer) {
        (, answer,,,) = _feedAdapter.latestRoundData();
    }
}
