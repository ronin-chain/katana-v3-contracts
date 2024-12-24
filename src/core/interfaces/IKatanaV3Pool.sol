// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "./pool/IKatanaV3PoolImmutables.sol";
import "./pool/IKatanaV3PoolState.sol";
import "./pool/IKatanaV3PoolDerivedState.sol";
import "./pool/IKatanaV3PoolActions.sol";
import "./pool/IKatanaV3PoolEvents.sol";

/// @title The interface for a Katana V3 Pool
/// @notice A Katana pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IKatanaV3Pool is
  IKatanaV3PoolImmutables,
  IKatanaV3PoolState,
  IKatanaV3PoolDerivedState,
  IKatanaV3PoolActions,
  IKatanaV3PoolEvents
{ }
