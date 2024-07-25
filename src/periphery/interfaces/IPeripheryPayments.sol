// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of RON
interface IPeripheryPayments {
  /// @notice Unwraps the contract's WRON balance and sends it to recipient as RON.
  /// @dev The amountMinimum parameter prevents malicious contracts from stealing WRON from users.
  /// @param amountMinimum The minimum amount of WRON to unwrap
  /// @param recipient The address receiving RON
  function unwrapWRON(uint256 amountMinimum, address recipient) external payable;

  /// @notice Refunds any RON balance held by this contract to the `msg.sender`
  /// @dev Useful for bundling with mint or increase liquidity that uses RON, or exact output swaps
  /// that use RON for the input amount
  function refundRON() external payable;

  /// @notice Transfers the full amount of a token held by this contract to recipient
  /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
  /// @param token The contract address of the token which will be transferred to `recipient`
  /// @param amountMinimum The minimum amount of token required for a transfer
  /// @param recipient The destination address of the token
  function sweepToken(address token, uint256 amountMinimum, address recipient) external payable;
}
