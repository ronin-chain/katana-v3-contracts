// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@katana/v3-contracts/core/libraries/LowGasSafeMath.sol";

import "./PeripheryPayments.sol";
import "../interfaces/IPeripheryPaymentsWithFee.sol";

import "../interfaces/external/IWRON.sol";
import "../libraries/TransferHelper.sol";

abstract contract PeripheryPaymentsWithFee is PeripheryPayments, IPeripheryPaymentsWithFee {
  using LowGasSafeMath for uint256;

  /// @inheritdoc IPeripheryPaymentsWithFee
  function unwrapWRONWithFee(uint256 amountMinimum, address recipient, uint256 feeBips, address feeRecipient)
    public
    payable
    override
  {
    require(feeBips > 0 && feeBips <= 100);

    uint256 balanceWRON = IWRON(WRON).balanceOf(address(this));
    require(balanceWRON >= amountMinimum, "Insufficient WRON");

    if (balanceWRON > 0) {
      IWRON(WRON).withdraw(balanceWRON);
      uint256 feeAmount = balanceWRON.mul(feeBips) / 10_000;
      if (feeAmount > 0) TransferHelper.safeTransferRON(feeRecipient, feeAmount);
      TransferHelper.safeTransferRON(recipient, balanceWRON - feeAmount);
    }
  }

  /// @inheritdoc IPeripheryPaymentsWithFee
  function sweepTokenWithFee(
    address token,
    uint256 amountMinimum,
    address recipient,
    uint256 feeBips,
    address feeRecipient
  ) public payable override {
    require(feeBips > 0 && feeBips <= 100);

    uint256 balanceToken = IERC20(token).balanceOf(address(this));
    require(balanceToken >= amountMinimum, "Insufficient token");

    if (balanceToken > 0) {
      uint256 feeAmount = balanceToken.mul(feeBips) / 10_000;
      if (feeAmount > 0) TransferHelper.safeTransfer(token, feeRecipient, feeAmount);
      TransferHelper.safeTransfer(token, recipient, balanceToken - feeAmount);
    }
  }
}
