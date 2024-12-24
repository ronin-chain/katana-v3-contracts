// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import "./interfaces/IKatanaV3Factory.sol";

import "./KatanaV3PoolDeployer.sol";

import "../external/interfaces/IKatanaGovernance.sol";

/// @title Canonical Katana V3 factory
/// @notice Deploys Katana V3 pools and manages ownership and control over pool protocol fees
contract KatanaV3Factory is IKatanaV3Factory, KatanaV3PoolDeployer {
  struct Fraction {
    uint8 numerator;
    uint8 denominator;
  }

  /// @inheritdoc IKatanaV3Factory
  address public override owner;
  /// @inheritdoc IKatanaV3Factory
  address public override treasury;
  /// @inheritdoc IKatanaV3Factory
  bool public override flashLoanEnabled;

  /// @inheritdoc IKatanaV3Factory
  mapping(uint24 => int24) public override feeAmountTickSpacing;
  /// @inheritdoc IKatanaV3Factory
  mapping(uint24 => Fraction) public override feeAmountProtocol;
  /// @inheritdoc IKatanaV3Factory
  mapping(address => mapping(address => mapping(uint24 => address))) public override getPool;

  constructor() {
    // disable initialization
    beacon = address(1);
  }

  modifier onlyOwner() {
    _checkOwner();
    _;
  }

  function _checkOwner() internal view virtual {
    require(owner == msg.sender, "KatanaV3Factory: FORBIDDEN");
  }

  function initialize(address beacon_, address owner_, address treasury_) external {
    require(beacon == address(0), "KatanaV3Factory: ALREADY_INITIALIZED");

    require(beacon_ != address(0), "KatanaV3Factory: INVALID_BEACON");
    require(owner_ != address(0), "KatanaV3Factory: INVALID_OWNER");
    require(treasury_ != address(0), "KatanaV3Factory: INVALID_TREASURY");

    // this beacon is treated as immutable
    // so there is no need to emit an event
    beacon = beacon_;

    // owner is also treated as immutable
    owner = owner_;

    treasury = treasury_;
    emit TreasuryChanged(address(0), treasury_);

    // swap fee 0.01% = 0.005% for LP + 0.005% for protocol
    // tick spacing of 1, equivalent to 0.01% between initializable ticks
    _enableFeeAmount(100, 1, 5, 10);

    // swap fee 0.3% = 0.25% for LP + 0.05% for protocol
    // tick spacing of 60, approximately 0.60% between initializable ticks
    _enableFeeAmount(3000, 60, 5, 30);

    // swap fee 1% = 0.85% for LP + 0.15% for protocol
    // tick spacing of 200, approximately 2.02% between initializable ticks
    _enableFeeAmount(10000, 200, 15, 100);
  }

  /// @inheritdoc IKatanaV3Factory
  function createPool(address tokenA, address tokenB, uint24 fee) external override returns (address pool) {
    require(msg.sender == IKatanaGovernance(owner).getPositionManager(), "KatanaV3Factory: INVALID_POSITION_MANAGER");

    require(tokenA != tokenB);
    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0));
    int24 tickSpacing = feeAmountTickSpacing[fee];
    require(tickSpacing != 0);
    require(getPool[token0][token1][fee] == address(0));
    pool = deploy(address(this), token0, token1, fee, tickSpacing);
    getPool[token0][token1][fee] = pool;
    // populate mapping in the reverse direction, deliberate choice to avoid the cost of comparing addresses
    getPool[token1][token0][fee] = pool;
    emit PoolCreated(token0, token1, fee, tickSpacing, pool);
  }

  function setTreasury(address _treasury) external override onlyOwner {
    require(_treasury != address(0), "KatanaV3Factory: INVALID_TREASURY");
    emit TreasuryChanged(treasury, _treasury);
    treasury = _treasury;
  }

  function toggleFlashLoanPermission() external override onlyOwner {
    flashLoanEnabled = !flashLoanEnabled;
    emit FlashLoanPermissionUpdated(flashLoanEnabled);
  }

  /// @inheritdoc IKatanaV3Factory
  function enableFeeAmount(uint24 fee, int24 tickSpacing, uint8 feeProtocolNum, uint8 feeProtocolDen)
    public
    override
    onlyOwner
  {
    require(fee < 1000000, "KatanaV3Factory: FEE_TOO_HIGH");
    // tick spacing is capped at 16384 to prevent the situation where tickSpacing is so large that
    // TickBitmap#nextInitializedTickWithinOneWord overflows int24 container from a valid tick
    // 16384 ticks represents a >5x price change with ticks of 1 bips
    require(tickSpacing > 0 && tickSpacing < 16384, "KatanaV3Factory: INVALID_TICK_SPACING");
    require(feeProtocolNum < feeProtocolDen, "KatanaV3Factory: INVALID_FEE_PROTOCOL");
    require(feeAmountTickSpacing[fee] == 0, "KatanaV3Factory: FEE_AMOUNT_ALREADY_ENABLED");

    _enableFeeAmount(fee, tickSpacing, feeProtocolNum, feeProtocolDen);
  }

  function _enableFeeAmount(uint24 fee, int24 tickSpacing, uint8 feeProtocolNum, uint8 feeProtocolDen) private {
    feeAmountTickSpacing[fee] = tickSpacing;
    feeAmountProtocol[fee] = Fraction(feeProtocolNum, feeProtocolDen);
    emit FeeAmountEnabled(fee, tickSpacing, feeProtocolNum, feeProtocolDen);
  }
}
