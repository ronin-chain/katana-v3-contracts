// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import "@openzeppelin/contracts/utils/Create2.sol";

import "./interfaces/IKatanaV3PoolDeployer.sol";
import "./interfaces/IKatanaV3PoolBeaconImmutables.sol";

abstract contract KatanaV3PoolDeployer is IKatanaV3PoolDeployer {
  /// @inheritdoc IKatanaV3PoolDeployer
  address public override beacon;

  struct Parameters {
    address factory;
    address token0;
    address token1;
    uint24 fee;
    int24 tickSpacing;
  }

  /// @inheritdoc IKatanaV3PoolDeployer
  Parameters public override parameters;

  /// @dev Deploys a pool with the given parameters by transiently setting the parameters storage slot and then
  /// clearing it after deploying the pool.
  /// @param factory The contract address of the Katana V3 factory
  /// @param token0 The first token of the pool by address sort order
  /// @param token1 The second token of the pool by address sort order
  /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
  /// @param tickSpacing The spacing between usable ticks
  function deploy(address factory, address token0, address token1, uint24 fee, int24 tickSpacing)
    internal
    returns (address pool)
  {
    parameters = Parameters({ factory: factory, token0: token0, token1: token1, fee: fee, tickSpacing: tickSpacing });
    bytes memory creationCode = IKatanaV3PoolBeaconImmutables(beacon).POOL_PROXY_INIT_CODE();
    bytes32 salt = keccak256(abi.encode(token0, token1, fee));
    pool = Create2.deploy(0, salt, creationCode);
    delete parameters;
  }
}
