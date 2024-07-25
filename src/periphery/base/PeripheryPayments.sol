// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IPeripheryPayments.sol";
import "../interfaces/external/IWRON.sol";

import "../libraries/TransferHelper.sol";

import "./PeripheryImmutableState.sol";

abstract contract PeripheryPayments is IPeripheryPayments, PeripheryImmutableState {
  receive() external payable {
    require(msg.sender == WRON, "Not WRON");
  }

  /// @inheritdoc IPeripheryPayments
  function unwrapWRON(uint256 amountMinimum, address recipient) public payable override {
    uint256 balanceWRON = IWRON(WRON).balanceOf(address(this));
    require(balanceWRON >= amountMinimum, "Insufficient WRON");

    if (balanceWRON > 0) {
      IWRON(WRON).withdraw(balanceWRON);
      TransferHelper.safeTransferRON(recipient, balanceWRON);
    }
  }

  /// @inheritdoc IPeripheryPayments
  function sweepToken(address token, uint256 amountMinimum, address recipient) public payable override {
    uint256 balanceToken = IERC20(token).balanceOf(address(this));
    require(balanceToken >= amountMinimum, "Insufficient token");

    if (balanceToken > 0) {
      TransferHelper.safeTransfer(token, recipient, balanceToken);
    }
  }

  /// @inheritdoc IPeripheryPayments
  function refundRON() external payable override {
    if (address(this).balance > 0) TransferHelper.safeTransferRON(msg.sender, address(this).balance);
  }

  /// @param token The token to pay
  /// @param payer The entity that must pay
  /// @param recipient The entity that will receive payment
  /// @param value The amount to pay
  function pay(address token, address payer, address recipient, uint256 value) internal {
    if (token == WRON && address(this).balance >= value) {
      // pay with WRON
      IWRON(WRON).deposit{ value: value }(); // wrap only what is needed to pay
      IWRON(WRON).transfer(recipient, value);
    } else if (payer == address(this)) {
      // pay with tokens already in the contract (for the exact input multihop case)
      TransferHelper.safeTransfer(token, recipient, value);
    } else {
      // pull payment
      TransferHelper.safeTransferFrom(token, payer, recipient, value);
    }
  }
}
