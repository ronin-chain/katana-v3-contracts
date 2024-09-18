// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import "../KatanaV3Pool.sol";

// used for testing time dependent behavior
contract MockTimeKatanaV3Pool is KatanaV3Pool {
  // Monday, October 5, 2020 9:00:00 AM GMT-05:00
  uint256 public time = 1601906400;

  /// @inheritdoc IKatanaV3PoolImmutables
  function initializeImmutables(address factory, address token0, address token1, uint24 fee, int24 tickSpacing)
    public
    override
  {
    super.initializeImmutables(factory, token0, token1, fee, tickSpacing);
    time = 1601906400;
  }

  function setPositionManager(address _positionManager) external {
    positionManager = _positionManager;
  }

  function setFeeProtocol(uint8 feeProtocolNumerator, uint8 feeProtocolDenominator) external {
    require(feeProtocolNumerator < feeProtocolDenominator, "INVALID_FEE");

    emit SetFeeProtocol(slot0.feeProtocolNum, slot0.feeProtocolDen, feeProtocolNumerator, feeProtocolDenominator);

    slot0.feeProtocolNum = feeProtocolNumerator;
    slot0.feeProtocolDen = feeProtocolDenominator;
  }

  function setFeeGrowthGlobal0X128(uint256 _feeGrowthGlobal0X128) external {
    feeGrowthGlobal0X128 = _feeGrowthGlobal0X128;
  }

  function setFeeGrowthGlobal1X128(uint256 _feeGrowthGlobal1X128) external {
    feeGrowthGlobal1X128 = _feeGrowthGlobal1X128;
  }

  function advanceTime(uint256 by) external {
    time += by;
  }

  function _blockTimestamp() internal view override returns (uint32) {
    return uint32(time);
  }
}
