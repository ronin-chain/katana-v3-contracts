// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

import { Test, console } from "forge-std/Test.sol";
import { PoolAddress } from "src/periphery/libraries/PoolAddress.sol";
import { KatanaV3PoolProxy } from "src/core/KatanaV3PoolProxy.sol";

contract PoolProxyInitCodeHashTest is Test {
  function test_POOL_PROXY_INIT_CODE_HASH() public pure {
    assertEq(
      PoolAddress.POOL_PROXY_INIT_CODE_HASH,
      keccak256(type(KatanaV3PoolProxy).creationCode),
      "PoolAddress.POOL_PROXY_INIT_CODE_HASH should match the creation code of the pool proxy"
    );
  }
}
