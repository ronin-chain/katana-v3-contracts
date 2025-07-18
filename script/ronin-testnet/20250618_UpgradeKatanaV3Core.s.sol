// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import { Script } from "forge-std/Script.sol";
import { KatanaV3Pool } from "src/core/KatanaV3Pool.sol";
import { KatanaV3PoolBeacon } from "src/core/KatanaV3PoolBeacon.sol";

contract Migration__20250618_UpgradeKatanaV3Core is Script {
  function run() public {
    address implementation = address(new KatanaV3Pool());
    KatanaV3PoolBeacon beacon = KatanaV3PoolBeacon(0x3cE42fE62db79401aC5E6466Fc9B769e4f68e419);

    vm.startBroadcast();
    beacon.upgradeTo(implementation);
    vm.stopBroadcast();
  }
}
