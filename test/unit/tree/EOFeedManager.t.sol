// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

// solhint-disable no-empty-blocks
// solhint-disable ordering
contract EOFeedManagerTests {
    function test_WhenNotOwner() external {
        // it should revert whitelistPublishers
        // it should revert setSupportedFeeds
    }

    modifier whenOwner() {
        _;
    }

    function test_WhenWhitelistPublishers() external whenOwner {
        // it should return publishers are whitelisted
    }

    function test_WhenSetSupportedFeeds() external whenOwner {
        // it should return feeds are supported
    }

    function test_WhenPublisherNotWhitelisted() external whenOwner {
        // it should revert updatePriceFeed |
        // it should revert
    }

    modifier whenPublisherWhitelisted() {
        _;
    }

    function test_WhenFeedNotSupported() external whenOwner whenPublisherWhitelisted {
        // it should revert updatePriceFeed
    }

    function test_WhenFeedSupported() external whenOwner whenPublisherWhitelisted {
        // it should updatePriceFeed
    }
}
