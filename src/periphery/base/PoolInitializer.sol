// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import "src/core/interfaces/IKatanaV3Factory.sol";
import "src/core/interfaces/IKatanaV3Pool.sol";

import "./PeripheryImmutableState.sol";
import "../interfaces/IPoolInitializer.sol";

import "../../external/libraries/AuthorizationLib.sol";

/// @title Creates and initializes V3 Pools
abstract contract PoolInitializer is IPoolInitializer, PeripheryImmutableState {
  /// @inheritdoc IPoolInitializer
  function createAndInitializePoolIfNecessary(address token0, address token1, uint24 fee, uint160 sqrtPriceX96)
    external
    payable
    override
    returns (address pool)
  {
    AuthorizationLib.checkPair(governance, token0, token1);

    require(token0 < token1);
    pool = IKatanaV3Factory(factory).getPool(token0, token1, fee);

    if (pool == address(0)) {
      pool = IKatanaV3Factory(factory).createPool(token0, token1, fee);
      IKatanaV3Pool(pool).initialize(sqrtPriceX96);
    } else {
      (uint160 sqrtPriceX96Existing,,,,,,,) = IKatanaV3Pool(pool).slot0();
      if (sqrtPriceX96Existing == 0) {
        IKatanaV3Pool(pool).initialize(sqrtPriceX96);
      }
    }
  }
}
