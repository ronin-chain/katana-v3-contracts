// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { DeployKatanaV3Periphery } from "../DeployKatanaV3Periphery.s.sol";
import { MixedRouteQuoterV1Testnet } from "src/periphery/lens/MixedRouteQuoterV1Testnet.sol";

contract DeployKatanaV3Testnet is DeployKatanaV3Periphery {
  address mixedRouteQuoterV1Testnet;

  function setUp() public override {
    proxyAdmin = 0x505d91E8fd2091794b45b27f86C045529fa92CD7;
    governance = 0x247F12836A421CDC5e22B93Bf5A9AAa0f521f986;
    treasury = 0x968D0Cd7343f711216817E617d3f92a23dC91c07;
    wron = 0xA959726154953bAe111746E265E6d754F48570E6;
    factoryV2 = 0x86587380C4c815Ba0066c90aDB2B45CC9C15E72c;

    sender = vm.rememberKey(vm.envUint("TESTNET_PK"));

    super.setUp();
  }

  function run() public override {
    super.run();

    vm.broadcast();
    mixedRouteQuoterV1Testnet = address(new MixedRouteQuoterV1Testnet(factory, factoryV2, wron));
    console.log("MixedRouteQuoterV1Testnet deployed:", mixedRouteQuoterV1Testnet);
  }
}
