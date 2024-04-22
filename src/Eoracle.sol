// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ITargetExitHelper} from "./interfaces/ITargetExitHelper.sol";
import {IEoracle} from "./interfaces/IEoracle.sol";

contract Eoracle is Initializable, OwnableUpgradeable, IEoracle {
    mapping(string => PriceFeed) public priceFeeds;
    mapping(address => bool) public whitelistedPublishers;
    mapping(string => bool) public supportedSymbols;
    ITargetExitHelper public targetExitHelper;

    // This is for debugging
    // event DebugLatency(
    //     uint256 originalTimestamp,
    //     uint256 currentTimestamp,
    //     uint256 latency
    // );

    modifier onlyWhitelisted() {
        require(whitelistedPublishers[msg.sender], "Caller is not whitelisted");
        _;
    }

    function initialize(ITargetExitHelper _targetExitHelper) external initializer {
        __Ownable_init();
        targetExitHelper = ITargetExitHelper(_targetExitHelper);
    }

    function setSupportedSymbols(string[] calldata symbols, bool[] calldata isSupported) external onlyOwner {
        for (uint256 i = 0; i < symbols.length;) {
            supportedSymbols[symbols[i]] = isSupported[i];
            unchecked {
                ++i;
            }
        }
    }

    function whitelistPublishers(address[] memory publishers, bool[] memory isWhitelisted) external onlyOwner {
        for (uint256 i = 0; i < publishers.length;) {
            whitelistedPublishers[publishers[i]] = isWhitelisted[i];
            unchecked {
                ++i;
            }
        }
    }

    function updatePriceFeed(
        string calldata symbol,
        uint256 value,
        uint256 timestamp,
        bytes memory proofData
    ) external onlyWhitelisted {
        require(supportedSymbols[symbol], "Symbol is not supported");
        targetExitHelper.submitAndExit(proofData);

        priceFeeds[symbol] = PriceFeed(value, timestamp);
    }

    function updatePriceFeeds(
        string[] calldata symbols,
        uint256[] memory values,
        uint256[] memory timestamps,
        bytes[] memory proofDatas
    ) external onlyWhitelisted {
        require(
            symbols.length == values.length && values.length == timestamps.length
                && timestamps.length == proofDatas.length,
            "Arrays' lengths are not equal"
        );
        for (uint256 i = 0; i < symbols.length;) {
            this.updatePriceFeed(symbols[i], values[i], timestamps[i], proofDatas[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getLatestPriceFeed(string calldata symbol) external view override returns (PriceFeed memory) {
        require(supportedSymbols[symbol], "Symbol is not supported");
        return priceFeeds[symbol];
    }

    function getLatestPriceFeeds(string[] calldata symbols) external view override returns (PriceFeed[] memory) {
        PriceFeed[] memory retVal = new PriceFeed[](symbols.length);
        for (uint256 i = 0; i < symbols.length;) {
            retVal[i] = this.getLatestPriceFeed(symbols[i]);
            unchecked {
                ++i;
            }
        }
        return retVal;
    }
}
