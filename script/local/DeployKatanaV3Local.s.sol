// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { DeployKatanaV3Periphery } from "../DeployKatanaV3Periphery.s.sol";
import { MixedRouteQuoterV1 } from "src/periphery/lens/MixedRouteQuoterV1.sol";
import { KatanaGovernanceMock } from "src/external/KatanaGovernanceMock.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract DeployKatanaV3Local is DeployKatanaV3Periphery {
  address mixedRouteQuoterV1;

  function setUp() public override {
    proxyAdmin = makeAddr("ProxyAdmin");
    governance = address(new KatanaGovernanceMock(true));
    treasury = makeAddr("RoninTreasury");
    wron = address(new ERC20Mock("Wrapped Ronin", "WRON", address(this), 10 ** 9 * 10 ** 9));
    factoryV2 = makeAddr("KatanaV2Factory");

    sender = DEFAULT_SENDER;

    super.setUp();
  }

  function run() public override {
    super.run();

    vm.broadcast();
    mixedRouteQuoterV1 = address(new MixedRouteQuoterV1(factory, factoryV2, wron));
    console.log("MixedRouteQuoterV1 deployed:", mixedRouteQuoterV1);
  }
}
