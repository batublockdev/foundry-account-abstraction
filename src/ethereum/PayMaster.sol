// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {IPaymaster} from "@account-abstraction/contracts/interfaces/IPaymaster.sol";
import "@account-abstraction/contracts/core/UserOperationLib.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {OracleLib} from "../libraries/OracleLib.sol";
import {console2} from "forge-std/console2.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";

contract PayMaster is IPaymaster, Ownable {
    using OracleLib for AggregatorV3Interface;

    /*//////////////////////////////////////////////////////////////
                                 ERROS
    //////////////////////////////////////////////////////////////*/

    error TokenPaymaster__OnlyEntryPoint();
    error TokenPaymaster__AllowanceNotEnough();
    error TokenPaymaster__NotEnoughToken();
    error TokenPaymaster__FaildTransfer();

    using UserOperationLib for PackedUserOperation;
    IEntryPoint public immutable entryPoint;
    IERC20 public immutable usdc;
    address public immutable ethPriceFeed; // tokens per gas unit

    uint256 private constant ADITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRICE_PRECISION = 1e18;

    constructor(
        address _entryPoint,
        address _usdc,
        address _ethPriceFeed
    ) Ownable(msg.sender) {
        entryPoint = IEntryPoint(_entryPoint);
        usdc = IERC20(_usdc);
        ethPriceFeed = _ethPriceFeed;
    }

    modifier onlyEntryPoint() {
        if (msg.sender != address(entryPoint)) {
            revert TokenPaymaster__OnlyEntryPoint();
        }
        _;
    }

    function validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 /* userOpHash */,
        uint256 maxCost
    )
        external
        override
        onlyEntryPoint
        returns (bytes memory context, uint256 validationData)
    {
        address sender = userOp.sender;
        uint256 tokenCost = _getPriceUsd(maxCost);
        console2.log("Token cost: %s", maxCost);
        console2.log("Token cost: %s", tokenCost);

        if (usdc.allowance(sender, address(this)) < tokenCost) {
            revert TokenPaymaster__AllowanceNotEnough();
        }
        if (usdc.balanceOf(sender) < tokenCost) {
            revert TokenPaymaster__NotEnoughToken();
        }

        // Pack context with info for postOp
        context = abi.encode(sender, tokenCost);
        validationData = 0; // 0 = valid forever (you could add timeouts here)
    }

    function postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost,
        uint256 actualUserOpFeePerGas
    ) external override onlyEntryPoint {
        (address sender, uint256 tokenCost) = abi.decode(
            context,
            (address, uint256)
        );

        bool success = usdc.transferFrom(sender, address(this), tokenCost);
        if (!success) {
            revert TokenPaymaster__FaildTransfer();
        }
    }

    /**
     * @notice follows CEI
     * @param amount the amount of the token to get the price for
     * @return  price of the token in USD
     */
    function _getPriceUsd(uint256 amount) internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(ethPriceFeed);
        (, int price, , , ) = priceFeed.staleCheckLastTestRoundData();
        return
            ((uint256(price) * ADITIONAL_FEED_PRECISION) * amount) /
            PRICE_PRECISION;
    }

    // Utility to deposit ETH into EntryPoint (done by contract owner or dApp)
    function depositToEntryPoint() external payable {
        entryPoint.depositTo{value: msg.value}(address(this));
    }

    // Optional: withdraw tokens
    function withdrawTokens(address to, uint256 amount) external onlyOwner {
        // Only owner logic would go here in real implementation
        usdc.transfer(to, amount);
    }

    // Optional: withdraw ETH
    function withdrawEth(
        address payable to,
        uint256 amount
    ) external onlyOwner {
        entryPoint.withdrawTo(to, amount);
    }
}
