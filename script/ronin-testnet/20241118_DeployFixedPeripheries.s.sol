// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { NonfungiblePositionManager } from "src/periphery/NonfungiblePositionManager.sol";
import { QuoterV2 } from "src/periphery/lens/QuoterV2.sol";
import { MixedRouteQuoterV1Testnet } from "src/periphery/lens/MixedRouteQuoterV1Testnet.sol";

contract Migration__20241118_DeployFixedPeripheries is Script {
  function run() public {
    address factory = 0x4E7236ff45d69395DDEFE1445040A8f3C7CD8819;
    address wron = 0xA959726154953bAe111746E265E6d754F48570E6;
    address tokenDescriptor = 0x913B5559097F6587fD69F40d81bB67E7ea6c3a91;
    address factoryV2 = 0x86587380C4c815Ba0066c90aDB2B45CC9C15E72c;

    vm.rememberKey(vm.envUint("TESTNET_PK"));
    vm.startBroadcast();

    address nonfungiblePositionManager = address(new NonfungiblePositionManager(factory, wron, tokenDescriptor));
    console.log("NonfungiblePositionManager (logic) deployed:", nonfungiblePositionManager);

    address quoterV2 = address(new QuoterV2(factory, wron));
    console.log("QuoterV2 deployed:", quoterV2);

    address mixedRouteQuoterV1Testnet = address(new MixedRouteQuoterV1Testnet(factory, factoryV2, wron));
    console.log("MixedRouteQuoterV1Testnet deployed:", mixedRouteQuoterV1Testnet);

    vm.stopBroadcast();
  }
}
