// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import { Test, console } from "forge-std/Test.sol";

import { IKatanaV3Pool } from "src/core/interfaces/IKatanaV3Pool.sol";

import { KatanaV3Factory } from "src/core/KatanaV3Factory.sol";
import { KatanaGovernanceMock } from "src/external/KatanaGovernanceMock.sol";

import { DeployKatanaV3Local } from "script/local/DeployKatanaV3Local.s.sol";

contract KatanaV3FactoryTest is Test {
  DeployKatanaV3Local script;
  KatanaGovernanceMock governance;

  KatanaV3Factory factory;
  address positionManager;

  function setUp() public {
    script = new DeployKatanaV3Local();
    script.setUp();
    script.run();

    factory = KatanaV3Factory(script.factory());
    positionManager = script.nonfungiblePositionManager();

    governance = KatanaGovernanceMock(script.governance());
    vm.label(address(this), "Router");
    governance.setRouter(address(this));
    governance.setPositionManager(address(positionManager));
  }

  function test_createPool() public {
    address token0 = makeAddr("token0");
    address token1 = makeAddr("token1");
    uint24 fee = 3000; // 0.3%
    int24 tickSpacing = 60;

    vm.prank(positionManager);
    address pool = factory.createPool(token0, token1, fee);

    assertEq(IKatanaV3Pool(pool).factory(), address(factory));
    assertEq(IKatanaV3Pool(pool).token0(), token0);
    assertEq(IKatanaV3Pool(pool).token1(), token1);
    assertEq(uint256(IKatanaV3Pool(pool).fee()), uint256(fee));
    assertEq(uint256(IKatanaV3Pool(pool).tickSpacing()), uint256(tickSpacing));
  }
}
