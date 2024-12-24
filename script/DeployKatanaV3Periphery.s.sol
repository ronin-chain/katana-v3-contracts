// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import { Script, console } from "forge-std/Script.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import { NonfungibleTokenPositionDescriptor } from "src/periphery/NonfungibleTokenPositionDescriptor.sol";
import { NonfungiblePositionManager } from "src/periphery/NonfungiblePositionManager.sol";
import { V3Migrator } from "src/periphery/V3Migrator.sol";
import { TickLens } from "src/periphery/lens/TickLens.sol";
import { QuoterV2 } from "src/periphery/lens/QuoterV2.sol";
import { KatanaInterfaceMulticall } from "src/periphery/lens/KatanaInterfaceMulticall.sol";
import { DeployKatanaV3Core } from "./DeployKatanaV3Core.s.sol";

abstract contract DeployKatanaV3Periphery is DeployKatanaV3Core {
  address public wron;
  address public factoryV2;

  address public tokenDescriptor;
  address public nonfungiblePositionManager;
  address public v3migrator;
  address public tickLens;
  address public quoterV2;
  address public katanaInterfaceMulticall;

  function setUp() public virtual override {
    require(wron != address(0));
    require(factoryV2 != address(0));

    super.setUp();
  }

  function run() public virtual override {
    super.run();

    vm.startBroadcast();

    tokenDescriptor = address(new NonfungibleTokenPositionDescriptor(wron, "RON"));
    console.log("NonfungibleTokenPositionDescriptor deployed:", tokenDescriptor);

    address nonfungiblePositionManagerImplementation =
      address(new NonfungiblePositionManager(factory, wron, tokenDescriptor));
    nonfungiblePositionManager = address(
      new TransparentUpgradeableProxy(
        nonfungiblePositionManagerImplementation,
        proxyAdmin,
        abi.encodeWithSelector(NonfungiblePositionManager.initialize.selector)
      )
    );
    require(
      NonfungiblePositionManager(payable(nonfungiblePositionManager)).governance() == governance, "governance mismatch"
    );
    console.log("NonfungiblePositionManager deployed:", nonfungiblePositionManager);

    v3migrator = address(new V3Migrator(factory, wron, nonfungiblePositionManager));
    console.log("V3Migrator deployed:", v3migrator);

    tickLens = address(new TickLens());
    console.log("TickLens deployed:", tickLens);

    quoterV2 = address(new QuoterV2(factory, wron));
    console.log("QuoterV2 deployed:", quoterV2);

    katanaInterfaceMulticall = address(new KatanaInterfaceMulticall());
    console.log("KatanaInterfaceMulticall deployed:", katanaInterfaceMulticall);

    vm.stopBroadcast();
  }

  function logParams() internal virtual override {
    super.logParams();

    console.log("WRON:", wron);
    console.log("factoryV2:", factoryV2);
  }
}
