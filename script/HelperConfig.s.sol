//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

contract HelperConig is Script{

    error HelperConig__InvalidChainId();

    struct NetworkConfig{
        address entryPoint
    }

    uint256 constant ETH_SEPOLIA_CHAIN_ID = 155111;
    uint256 constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint256 constant LOCAL_CHAIN_ID = 31337;

    NetworkConfig public localNetworkConfig;
    mapping (uint256 chainId => NetworkConfig) networkCOnfigs;

    constructor(){
        networkCOnfigs[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
    }
    function getConfig() public returns (NetworkConfig memory){
        return getConfigByChainId(block.chainid);
    }
    function getConfigByChainId(uint256 chainId) public  returns (NetworkConfig memory){
        if(chainId== LOCAL_CHAIN_ID){
            return getAnvilConfig();
        }else if(networkCOnfigs[chainId].entryPoint != address(0)){
            return networkCOnfigs[chainId];
        }else{
            revert HelperConig__InvalidChainId();
        }
    }
    function getEthSepoliaConfig() public pure returns (NetworkConfig memory){
        return NetworkConfig({entryPoint: })
    }
    function getZkSyncSepoliaConfig() public pure returns (NetworkConfig memory){
        return NetworkConfig({entryPoint: address(0)});
    }
    function getAnvilConfig() public pure returns (NetworkConfig memory){
        if(localNetworkConfig.entryPoint != address(0)){
            return localNetworkConfig;
        }
    }
}