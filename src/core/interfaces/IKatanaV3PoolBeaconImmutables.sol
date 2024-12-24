// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Katana V3 Factory immutables
interface IKatanaV3PoolBeaconImmutables {
  /// @dev The init code for the pool proxy
  function POOL_PROXY_INIT_CODE() external view returns (bytes memory);

  /// @dev The init code hash for the pool proxy
  function POOL_PROXY_INIT_CODE_HASH() external view returns (bytes32);
}
