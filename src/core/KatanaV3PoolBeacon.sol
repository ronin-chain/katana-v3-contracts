// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import "@openzeppelin/contracts/proxy/UpgradeableBeacon.sol";

import "./interfaces/IKatanaV3PoolBeaconImmutables.sol";

import "./KatanaV3PoolProxy.sol";

/// @title Beacon for deploying and upgrading Katana V3 pools
contract KatanaV3PoolBeacon is IKatanaV3PoolBeaconImmutables, UpgradeableBeacon {
  /// @inheritdoc IKatanaV3PoolBeaconImmutables
  bytes public constant override POOL_PROXY_INIT_CODE = type(KatanaV3PoolProxy).creationCode;

  /// @inheritdoc IKatanaV3PoolBeaconImmutables
  bytes32 public constant override POOL_PROXY_INIT_CODE_HASH = keccak256(POOL_PROXY_INIT_CODE);

  constructor(address poolImplementation) UpgradeableBeacon(poolImplementation) { }
}
