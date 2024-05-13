// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IEOFeed } from "../adapters/interfaces/IEOFeed.sol";

contract EoracleConsumerExampleFeed {
    // solhint-disable-next-line var-name-mixedcase
    IEOFeed private _feed;

    constructor(address feed) {
        _feed = IEOFeed(feed);
    }

    function setFeed(address feed) external {
        _feed = IEOFeed(feed);
    }

    function getFeed() external view returns (IEOFeed) {
        return _feed;
    }

    function getPrice() external view returns (int256 answer) {
        (, answer,,,) = _feed.latestRoundData();
    }
}
