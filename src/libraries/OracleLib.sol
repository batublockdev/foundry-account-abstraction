//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error OracleLib_StalePrice();

library OracleLib {
    uint256 private constant TIMEOUT = 3 hours;

    function staleCheckLastTestRoundData(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint80, int256, uint256, uint256, uint80) {
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        uint256 sencondsSinceUpdate = block.timestamp - updatedAt;
        if (sencondsSinceUpdate > TIMEOUT) revert OracleLib_StalePrice();
        return (roundId, answer, startedAt, updatedAt, answeredInRound);
    }
}
