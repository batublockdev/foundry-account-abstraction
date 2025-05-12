//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";
import {console2} from "forge-std/console2.sol";
import {ERC20Mock} from "test/mock/ERC20Mock.sol";

contract HelperConfig is Script {
    error HelperConig__InvalidChainId();

    struct NetworkConfig {
        address entryPoint;
        address usd;
        address[2] account;
    }

    uint256 constant ETH_SEPOLIA_CHAIN_ID = 155111;
    uint256 constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint256 constant LOCAL_CHAIN_ID = 31337;
    address constant BURNER_WALLET = 0x27fe1ac5A0eBD0c969C51B1f040ad704C4aB20A0;
    address constant ANVIL_DEFAULT_ACCOUNT =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant ANVIL_DEFAULT_ACCOUNT2 =
        0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    NetworkConfig public localNetworkConfig =
        NetworkConfig({
            entryPoint: address(0),
            usd: address(0),
            account: [address(0), address(0)]
        });
    mapping(uint256 chainId => NetworkConfig) networkCOnfigs;

    constructor() {
        networkCOnfigs[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        console2.log("GetConfig");
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (chainId == LOCAL_CHAIN_ID) {
            console2.log("Local chain id");
            return getAnvilConfig();
        } else if (networkCOnfigs[chainId].entryPoint != address(0)) {
            return networkCOnfigs[chainId];
        } else {
            revert HelperConig__InvalidChainId();
        }
    }

    function getEthSepoliaConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789,
                usd: address(0),
                account: [address(0), address(0)]
            });
    }

    function getZkSyncSepoliaConfig()
        public
        pure
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                entryPoint: address(0),
                usd: address(0),
                account: [address(0), address(0)]
            });
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.entryPoint != address(0)) {
            console2.log("xxx");
            return localNetworkConfig;
        }
        // deploy mocks
        console2.log("Deploying mocks...");
        vm.startBroadcast(ANVIL_DEFAULT_ACCOUNT);
        EntryPoint entryPoint = new EntryPoint();
        ERC20Mock usdc = new ERC20Mock(
            "USD Coin",
            "USDC",
            6,
            address(entryPoint)
        );
        vm.stopBroadcast();
        console2.log("Mocks deployed!");

        localNetworkConfig = NetworkConfig({
            entryPoint: address(entryPoint),
            usd: address(usdc),
            account: [ANVIL_DEFAULT_ACCOUNT, ANVIL_DEFAULT_ACCOUNT2]
        });

        return localNetworkConfig;
    }
}
