// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {PayMaster} from "src/ethereum/PayMaster.sol";
import {DeployPayMaster} from "script/DeployPayMaster.s.sol";
import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {ERC20Mock} from "./mock/ERC20Mock.sol";
import {SendPackedUserOp, PackedUserOperation, IEntryPoint} from "script/SendPankedUserOp.s.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";

contract PayMasterTest is Test, ZkSyncChainChecker {
    using MessageHashUtils for bytes32;

    HelperConfig helperConfig;
    PayMaster payMaster;
    MinimalAccount minimalAccount;
    ERC20Mock usdc;
    SendPackedUserOp sendPackedUserOp;
    address constant ANVIL_DEFAULT_ACCOUNT =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant ANVIL_DEFAULT_ACCOUNT2 =
        0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    uint256 ANVIL_DEFAULT_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 ANVIL_DEFAULT_KEY2 =
        0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;

    address randomuser = makeAddr("randomUser");
    address userX = makeAddr("userX");

    uint256 constant AMOUNT = 1e18;

    function setUp() public skipZkSync {
        DeployPayMaster deployPayMaster = new DeployPayMaster();
        (helperConfig, payMaster) = deployPayMaster.deployPayMaster();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        vm.prank(ANVIL_DEFAULT_ACCOUNT);
        minimalAccount = new MinimalAccount(
            config.entryPoint,
            config.account[1]
        );
        usdc = ERC20Mock(config.usd);
        sendPackedUserOp = new SendPackedUserOp();
    }

    function testValidationOfUserOpsPaymaster() public skipZkSync {
        // Arrange
        usdc.mint(address(minimalAccount), 2 ether);
        vm.prank(address(minimalAccount));
        usdc.approve(address(payMaster), 2 ether);

        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(
            ERC20Mock.transferx.selector,
            userX,
            AMOUNT
        );
        bytes memory executeCallData = abi.encodeWithSelector(
            MinimalAccount.execute.selector,
            dest,
            value,
            functionData
        );
        PackedUserOperation memory packedUserOp = sendPackedUserOp
            .generateSignedUserOperationPayMaster(
                executeCallData,
                helperConfig.getConfig(),
                address(minimalAccount),
                address(payMaster)
            );

        // Act
        vm.deal(ANVIL_DEFAULT_ACCOUNT2, 1 ether);
        vm.prank(ANVIL_DEFAULT_ACCOUNT2);
        payMaster.depositToEntryPoint{value: 1 ether}();

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = packedUserOp;

        // Act
        vm.prank(randomuser);
        IEntryPoint(helperConfig.getConfig().entryPoint).handleOps(
            ops,
            payable(randomuser)
        );
        console2.log(payMaster.owner()); // log owner address
        vm.startPrank(ANVIL_DEFAULT_ACCOUNT2);
        payMaster.withdrawTokens(
            ANVIL_DEFAULT_ACCOUNT2,
            usdc.balanceOf(address(payMaster))
        );
        vm.stopPrank();

        // Assert
        assertEq(usdc.balanceOf(userX), AMOUNT);
        assertLt(usdc.balanceOf(address(minimalAccount)), AMOUNT);
        assertLt(0, usdc.balanceOf(ANVIL_DEFAULT_ACCOUNT2));
    }
}
