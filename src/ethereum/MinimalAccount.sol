// SPDX-Liciense-Identifier: MIT
pragma solidity ^0.8.24;

import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract MinimalAccount is IAccount, Ownable {
    error MinimalAccount__OnlyEntryPoint();
    error MinimalAccount__OnlyEntryPointOrOwner();
    error MinimalAccount__CallFailed(bytes result);

    IEntryPoint public immutable i_entryPoint;

    modifier OnlyEntryPoint() {
        if (msg.sender != address(i_entryPoint)) {
            revert MinimalAccount__OnlyEntryPoint();
        }
        _;
    }

    modifier OnlyEntryPointOrOwner() {
        if (msg.sender != address(i_entryPoint) && msg.sender != owner()) {
            revert MinimalAccount__OnlyEntryPointOrOwner();
        }
        _;
    }

    constructor(address entryPoint) Ownable(msg.sender) {
        i_entryPoint = IEntryPoint(entryPoint);
    }

    receive() external payable {}

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external OnlyEntryPoint returns (uint256 validationData) {
        validationData = _validateSignature(userOp, userOpHash);
        _payPreFunds(missingAccountFunds);
    }

    function execute(
        address target,
        uint256 value,
        bytes calldata data
    ) external OnlyEntryPoint {
        // Execute the transaction
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            revert MinimalAccount__CallFailed(result);
        }
    }

    function _validateSignature(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) internal view returns (uint256 validationData) {
        // Check if the signature is valid
        bytes32 hash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(hash, userOp.signature);
        if (signer != owner()) {
            return SIG_VALIDATION_FAILED;
        } else {
            return SIG_VALIDATION_SUCCESS;
        }
    }

    function _payPreFunds(uint256 missingAccountFunds) internal {
        if (missingAccountFunds > 0) {
            // Transfer the required funds to the contract
            (bool success, ) = payable(msg.sender).call{
                value: missingAccountFunds,
                gas: type(uint256).max
            }("");
            (success);
        }
    }

    function getIEntryPoint() external view returns (address) {
        return address(i_entryPoint);
    }
}
