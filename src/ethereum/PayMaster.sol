// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {IPaymaster} from "@account-abstraction/contracts/interfaces/IPaymaster.sol";
import "@account-abstraction/contracts/core/UserOperationLib.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";

contract TokenPaymaster is IPaymaster {
    /*//////////////////////////////////////////////////////////////
                                 ERROS
    //////////////////////////////////////////////////////////////*/

    error TokenPaymaster__OnlyEntryPoint();
    error TokenPaymaster__AllowanceNotEnough();
    error TokenPaymaster__OnlyOwner();
    error TokenPaymaster__NotEnoughToken();
    error TokenPaymaster__FaildTransfer();


    using UserOperationLib for PackedUserOperation;
    IEntryPoint public immutable entryPoint;
    IERC20 public immutable usdc;
    uint256 public immutable tokenGasPrice; // tokens per gas unit
    address private immutable i_owner;

    constructor(IEntryPoint _entryPoint, IERC20 _usdc, uint256 _tokenGasPrice) {
        entryPoint = _entryPoint;
        usdc = _usdc;
        tokenGasPrice = _tokenGasPrice;
        i_owner = msg.sender
    }

    modifier onlyEntryPoint() {
        if(msg.sender == address(entryPoint)){
            revert TokenPaymaster__OnlyEntryPoint();
        }
        _;
    }
    modifier onlyOwner() {
        if(msg.sender == i_owner){
            revert TokenPaymaster__OnlyOwner();
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
        address sender = userOp.getSender();
        uint256 tokenCost = maxCost * tokenGasPrice;

        if(
            usdc.allowance(sender, address(this)) >= tokenCost,
        ){
            revert TokenPaymaster__AllowanceNotEnough();
        }
        if(
            usdc.balanceOf(sender) >= tokenCost,
        ){
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
        if(success){
            revert TokenPaymaster__FaildTransfer();
        }
    }

    // Utility to deposit ETH into EntryPoint (done by contract owner or dApp)
    function depositToEntryPoint() external payable {
        entryPoint.depositTo{value: msg.value}(address(this));
    }

    // Optional: withdraw tokens
    function withdrawTokens(address to, uint256 amount) onlyOwner external {
        // Only owner logic would go here in real implementation
        usdc.transfer(to, amount);
    }

    // Optional: withdraw ETH
    function withdrawEth(address payable to, uint256 amount) onlyOwner external {
        entryPoint.withdrawTo(to, amount);
    }
}
