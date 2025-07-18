// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import { Script } from "forge-std/Script.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import { KatanaV3Pool } from "src/core/KatanaV3Pool.sol";
import { KatanaV3Factory } from "src/core/KatanaV3Factory.sol";
import { KatanaV3PoolBeacon } from "src/core/KatanaV3PoolBeacon.sol";
import { NonfungiblePositionManager } from "src/periphery/NonfungiblePositionManager.sol";

contract Migration__20250618_UpgradeKatanaV3Core is Script {
  address positionManager = 0x7C2716803c09cd5eeD78Ba40117084af3c803565;
  address factory;
  address beacon;

  function setUp() public {
    NonfungiblePositionManager positionManagerContract = NonfungiblePositionManager(positionManager);
    factory = positionManagerContract.factory();
    KatanaV3Factory katanaV3Factory = KatanaV3Factory(factory);
    beacon = katanaV3Factory.beacon();
  }

  function run() public {
    address implementation = address(new KatanaV3Pool());

    vm.startBroadcast();
    TransparentUpgradeableProxy(factory).upgradeTo(address(new KatanaV3Factory()));
    KatanaV3PoolBeacon(beacon).upgradeTo(implementation);
    vm.stopBroadcast();
  }
}
