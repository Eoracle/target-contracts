// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IEOFeedAdapter } from "../adapters/interfaces/IEOFeedAdapter.sol";

contract EoracleConsumerExampleFeedAdapter {
    // solhint-disable-next-line var-name-mixedcase
    IEOFeedAdapter private _feedAdapter;

    constructor(address feedAdapter) {
        // @audit-info Aderyn: L-3: Missing checks for address(0) when assigning values to address state variables
        _feedAdapter = IEOFeedAdapter(feedAdapter);
    }

    function setFeed(address feedAdapter) external {
        // @audit-info Aderyn: L-3: Missing checks for address(0) when assigning values to address state variables
        _feedAdapter = IEOFeedAdapter(feedAdapter);
    }

    function getFeed() external view returns (IEOFeedAdapter) {
        return _feedAdapter;
    }

    function getPrice() external view returns (int256 answer) {
        (, answer,,,) = _feedAdapter.latestRoundData();
    }
}
