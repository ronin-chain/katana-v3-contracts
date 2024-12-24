// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import { Script, console } from "forge-std/Script.sol";
import { KatanaV3Factory } from "src/core/KatanaV3Factory.sol";
import { KatanaV3Pool } from "src/core/KatanaV3Pool.sol";
import { KatanaV3PoolBeacon } from "src/core/KatanaV3PoolBeacon.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

abstract contract DeployKatanaV3Core is Script {
  address public sender;
  address public proxyAdmin;
  address public governance;
  address public treasury;

  address poolImplementation;
  address public beacon;
  address public factory;

  function setUp() public virtual {
    require(proxyAdmin != address(0));
    require(governance != address(0));
    require(treasury != address(0));
    logParams();
  }

  function run() public virtual {
    vm.startBroadcast();

    poolImplementation = address(new KatanaV3Pool());
    beacon = address(new KatanaV3PoolBeacon(poolImplementation));

    address factoryImplementation = address(new KatanaV3Factory());
    factory = address(
      new TransparentUpgradeableProxy(
        factoryImplementation,
        proxyAdmin,
        abi.encodeWithSelector(KatanaV3Factory.initialize.selector, beacon, governance, treasury)
      )
    );

    console.log("KatanaV3Factory deployed:", factory);

    vm.stopBroadcast();
  }

  function logParams() internal virtual {
    console.log("governance:", governance);
    console.log("treasury:", treasury);
  }
}
