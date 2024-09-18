// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import "@openzeppelin/contracts/utils/Create2.sol";

import "../interfaces/IKatanaV3PoolDeployer.sol";
import "../interfaces/IKatanaV3PoolBeaconImmutables.sol";

import "../KatanaV3PoolBeacon.sol";
import "./MockTimeKatanaV3Pool.sol";

contract MockTimeKatanaV3PoolDeployer is IKatanaV3PoolDeployer {
  struct Parameters {
    address factory;
    address token0;
    address token1;
    uint24 fee;
    int24 tickSpacing;
  }

  address public immutable override beacon;

  Parameters public override parameters;

  event PoolDeployed(address pool);

  constructor() {
    address poolImplemenation = address(new MockTimeKatanaV3Pool());
    beacon = address(new KatanaV3PoolBeacon(poolImplemenation));
  }

  function deploy(address factory, address token0, address token1, uint24 fee, int24 tickSpacing)
    external
    returns (address pool)
  {
    parameters = Parameters({ factory: factory, token0: token0, token1: token1, fee: fee, tickSpacing: tickSpacing });
    bytes memory creationCode = IKatanaV3PoolBeaconImmutables(beacon).POOL_PROXY_INIT_CODE();
    bytes32 salt = keccak256(abi.encode(token0, token1, fee));
    pool = Create2.deploy(0, salt, creationCode);
    emit PoolDeployed(pool);
    delete parameters;
  }
}
