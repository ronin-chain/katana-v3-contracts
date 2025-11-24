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

contract Migration__20250618_UpgradeKatanaV3Core is Script {
  address proxyAdmin = 0x505d91E8fd2091794b45b27f86C045529fa92CD7;
  address positionManager = 0x7C2716803c09cd5eeD78Ba40117084af3c803565;
  address positionDescriptor = 0x913B5559097F6587fD69F40d81bB67E7ea6c3a91;

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
    vm.rememberKey(vm.envUint("RONIN_TESTNET_PK"));

    vm.startBroadcast(owner);
    // upgrade position manager
    ProxyAdmin(proxyAdmin).upgrade(
      TransparentUpgradeableProxy(payable(positionManager)),
      address(new NonfungiblePositionManager(factory, weth9, positionDescriptor))
    );

    // upgrade factory
    ProxyAdmin(proxyAdmin).upgrade(TransparentUpgradeableProxy(payable(factory)), address(new KatanaV3Factory()));

    // upgrade beacon
    KatanaV3PoolBeacon(beacon).upgradeTo(address(new KatanaV3Pool()));

    // deploy v3 migrator
    address v3migrator = address(new V3Migrator(factory, weth9, positionManager));
    vm.stopBroadcast();
  }
}
