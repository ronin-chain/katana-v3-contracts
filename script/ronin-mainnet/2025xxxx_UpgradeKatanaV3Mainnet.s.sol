// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import { KatanaV3Pool } from "src/core/KatanaV3Pool.sol";
import { KatanaV3Factory } from "src/core/KatanaV3Factory.sol";
import { KatanaV3PoolBeacon } from "src/core/KatanaV3PoolBeacon.sol";
import { NonfungiblePositionManager } from "src/periphery/NonfungiblePositionManager.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/ProxyAdmin.sol";
import { V3Migrator } from "src/periphery/V3Migrator.sol";

contract Migration__2025xxxx_UpgradeKatanaV3Mainnet is Script {
  address proxyAdmin = 0x9D05D1F5b0424F8fDE534BC196FFB6Dd211D902a;
  address positionManager = 0x7cF0fb64d72b733695d77d197c664e90D07cF45A;
  address positionDescriptor = 0x8766648aA6586cC7Cd2cDb2Bd911eec78Cab89Ea;

  address owner;
  address factory;
  address weth9;
  address beacon;

  function setUp() public {
    owner = ProxyAdmin(proxyAdmin).owner();
    NonfungiblePositionManager positionManagerContract = NonfungiblePositionManager(payable(positionManager));
    factory = positionManagerContract.factory();
    weth9 = positionManagerContract.WETH9();
    KatanaV3Factory katanaV3Factory = KatanaV3Factory(factory);
    beacon = katanaV3Factory.beacon();
  }

  function run() public {
    vm.rememberKey(vm.envUint("MAINNET_PK"));

    vm.startBroadcast(owner);
    address newPositionManagerLogic = address(new NonfungiblePositionManager(factory, weth9, positionDescriptor));
    console.log("NonfungiblePositionManager logic deployed:", newPositionManagerLogic);

    // upgrade position manager
    ProxyAdmin(proxyAdmin).upgrade(TransparentUpgradeableProxy(payable(positionManager)), newPositionManagerLogic);
    console.log("NonfungiblePositionManager upgraded");

    // upgrade factory
    address newFactoryLogic = address(new KatanaV3Factory());
    console.log("KatanaV3Factory logic deployed:", newFactoryLogic);
    ProxyAdmin(proxyAdmin).upgrade(TransparentUpgradeableProxy(payable(factory)), newFactoryLogic);
    console.log("KatanaV3Factory upgraded");

    // upgrade beacon
    address newBeaconLogic = address(new KatanaV3Pool());
    console.log("KatanaV3PoolBeacon logic deployed:", newBeaconLogic);
    KatanaV3PoolBeacon(beacon).upgradeTo(newBeaconLogic);
    console.log("KatanaV3PoolBeacon upgraded");

    // deploy v3 migrator
    address v3migrator = address(new V3Migrator(factory, weth9, positionManager));
    console.log("V3Migrator deployed:", v3migrator);
    vm.stopBroadcast();
  }
}
