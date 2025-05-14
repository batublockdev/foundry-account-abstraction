//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {PayMaster} from "../src/ethereum/PayMaster.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {console2} from "forge-std/console2.sol";

contract DeployPayMaster is Script {
    function run() external {
        deployPayMaster();
    }

    function deployPayMaster() public returns (HelperConfig, PayMaster) {
        //address addr = 0x1234567890123456789012345678901234567890;
        //bytes memory b = abi.encode(addr);
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        address sender = config.account[1];
        console2.log("Sender: %s", sender);
        vm.startBroadcast(sender);
        PayMaster payMaster = new PayMaster(
            config.entryPoint,
            config.usd,
            config.priceFeed
        );
        //minimalAccount.transferOwnership(msg.sender);
        vm.stopBroadcast();
        return (helperConfig, payMaster);
    }
}
