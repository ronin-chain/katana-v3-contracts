// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import "../interfaces/IERC20Minimal.sol";

import "../interfaces/callback/IKatanaV3SwapCallback.sol";
import "../interfaces/IKatanaV3Pool.sol";

contract TestKatanaV3SwapPay is IKatanaV3SwapCallback {
  function swap(
    address pool,
    address recipient,
    bool zeroForOne,
    uint160 sqrtPriceX96,
    int256 amountSpecified,
    uint256 pay0,
    uint256 pay1
  ) external {
    IKatanaV3Pool(pool).swap(recipient, zeroForOne, amountSpecified, sqrtPriceX96, abi.encode(msg.sender, pay0, pay1));
  }

  function katanaV3SwapCallback(int256, int256, bytes calldata data) external override {
    (address sender, uint256 pay0, uint256 pay1) = abi.decode(data, (address, uint256, uint256));

    if (pay0 > 0) {
      IERC20Minimal(IKatanaV3Pool(msg.sender).token0()).transferFrom(sender, msg.sender, uint256(pay0));
    } else if (pay1 > 0) {
      IERC20Minimal(IKatanaV3Pool(msg.sender).token1()).transferFrom(sender, msg.sender, uint256(pay1));
    }
  }
}
