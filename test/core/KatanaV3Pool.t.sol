// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

import { Test, console } from "forge-std/Test.sol";

import { ERC20Mock } from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

import { IKatanaV3Pool } from "src/core/interfaces/IKatanaV3Pool.sol";
import { INonfungiblePositionManager } from "src/periphery/interfaces/INonfungiblePositionManager.sol";

import { TickMath } from "src/core/libraries/TickMath.sol";

import { KatanaV3Pool } from "src/core/KatanaV3Pool.sol";
import { KatanaV3Factory } from "src/core/KatanaV3Factory.sol";
import { NonfungiblePositionManager } from "src/periphery/NonfungiblePositionManager.sol";

import { KatanaGovernanceMock } from "src/external/KatanaGovernanceMock.sol";

import { DeployKatanaV3Local } from "script/local/DeployKatanaV3Local.s.sol";

contract KatanaV3PoolTest is Test {
  DeployKatanaV3Local script;
  KatanaGovernanceMock governance;

  uint24[] fees = [100, 3000, 10000];
  int24[] tickSpacings = [2, 60, 200];

  KatanaV3Factory factory;
  NonfungiblePositionManager positionManager;
  address treasury;

  // Deploy token1 first to make token0 < token1
  address token1 = address(new ERC20Mock("Token1", "TK1", address(this), 10 ** 9 * 10 ** 9));
  address token0 = address(new ERC20Mock("Token0", "TK0", address(this), 10 ** 9 * 10 ** 9));

  KatanaV3Pool[] pools;

  function setUp() public {
    vm.label(token0, "Token0");
    vm.label(token1, "Token1");

    script = new DeployKatanaV3Local();
    script.setUp();
    script.run();

    factory = KatanaV3Factory(script.factory());
    positionManager = NonfungiblePositionManager(payable(script.nonfungiblePositionManager()));
    treasury = script.treasury();

    governance = KatanaGovernanceMock(script.governance());
    vm.label(address(this), "Router");
    governance.setRouter(address(this));
    governance.setPositionManager(address(positionManager));

    // price: token0 = 10 token1
    pools.push(
      KatanaV3Pool(
        positionManager.createAndInitializePoolIfNecessary(token0, token1, 100, 250541448375047931186413801569)
      )
    );
    pools.push(
      KatanaV3Pool(
        positionManager.createAndInitializePoolIfNecessary(token0, token1, 3000, 250541448375047931186413801569)
      )
    );
    pools.push(
      KatanaV3Pool(
        positionManager.createAndInitializePoolIfNecessary(token0, token1, 10000, 250541448375047931186413801569)
      )
    );

    vm.label(address(pools[0]), "pool[0.01%]");
    vm.label(address(pools[1]), "pool[0.3%]");
    vm.label(address(pools[2]), "pool[1%]");

    for (uint256 i = 0; i < pools.length; ++i) {
      ERC20Mock(token0).approve(address(positionManager), 10 ** 9 * 10 ** 9);
      ERC20Mock(token1).approve(address(positionManager), 10 ** 9 * 10 ** 9);
    }

    for (uint256 i = 0; i < pools.length; ++i) {
      KatanaV3Pool pool = pools[i];
      int24 tickSpacing = tickSpacings[i];

      address poolToken0 = pool.token0();
      address poolToken1 = pool.token1();
      uint24 poolFee = pool.fee();

      positionManager.mint(
        INonfungiblePositionManager.MintParams({
          token0: poolToken0,
          token1: poolToken1,
          fee: poolFee,
          tickLower: (23027 - 10000) / tickSpacing * tickSpacing,
          tickUpper: (23027 + 10000) / tickSpacing * tickSpacing,
          amount0Desired: 1_000_000,
          amount1Desired: 1_000_000,
          amount0Min: 1,
          amount1Min: 1,
          recipient: address(this),
          deadline: block.timestamp
        })
      );
    }
  }

  function katanaV3MintCallback(uint256 amount0Owed, uint256 amount1Owed, bytes calldata) external {
    ERC20Mock(token0).transfer(msg.sender, amount0Owed);
    ERC20Mock(token1).transfer(msg.sender, amount1Owed);
  }

  function katanaV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata) external {
    if (amount0Delta > 0) ERC20Mock(token0).transfer(msg.sender, uint256(amount0Delta));
    if (amount1Delta > 0) ERC20Mock(token1).transfer(msg.sender, uint256(amount1Delta));
  }

  function test_swap() public {
    for (uint256 i = 0; i < 3; ++i) {
      KatanaV3Pool pool = pools[i];
      pool.swap(address(this), true, 10_000_000, TickMath.MIN_SQRT_RATIO + 1, "");
      console.log(ERC20Mock(token0).balanceOf(treasury), ERC20Mock(token1).balanceOf(treasury));
    }
  }
}
