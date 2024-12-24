// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Katana V3 Factory
/// @notice The Katana V3 Factory facilitates creation of Katana V3 pools and control over the protocol fees
interface IKatanaV3Factory {
  /// @notice Emitted when the treasury address is changed
  /// @param oldTreasury The treasury address before the treasury was changed
  /// @param newTreasury The treasury address after the treasury was changed
  event TreasuryChanged(address indexed oldTreasury, address indexed newTreasury);

  /// @notice Emitted when the ability to call the `flash` function on KatanaV3Pool is toggled
  /// @param enabled Whether flash loans are enabled
  event FlashLoanPermissionUpdated(bool indexed enabled);

  /// @notice Emitted when a pool is created
  /// @param token0 The first token of the pool by address sort order
  /// @param token1 The second token of the pool by address sort order
  /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
  /// @param tickSpacing The minimum number of ticks between initialized ticks
  /// @param pool The address of the created pool
  event PoolCreated(
    address indexed token0, address indexed token1, uint24 indexed fee, int24 tickSpacing, address pool
  );

  /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
  /// @param fee The enabled fee, denominated in hundredths of a bip
  /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
  /// @param protocolFeeNum The numerator of the protocol fee as a ratio of the fee amount that sent to the treasury
  /// @param protocolFeeDen The denominator of the protocol fee as a ratio of the fee amount that sent to the treasury
  event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing, uint8 protocolFeeNum, uint8 protocolFeeDen);

  /// @notice Returns the current owner of the factory
  /// @dev Can be changed by the current owner via setOwner
  /// @return The address of the factory owner
  function owner() external view returns (address);

  /// @notice Returns the treasury address that receives protocol fees
  /// @dev Can be changed by the current owner via setTreasury
  /// @return The address of the treasury
  function treasury() external view returns (address);

  /// @notice Returns whether flash loans are enabled
  /// @dev Can be changed by the current owner via toggleFlashLoanPermission
  /// @return Whether flash loans are enabled
  function flashLoanEnabled() external view returns (bool);

  /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
  /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
  /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
  /// @return The tick spacing
  function feeAmountTickSpacing(uint24 fee) external view returns (int24);

  /// @notice Returns the default protocol fee ratio for a given fee amount, if enabled, or 0 if not enabled
  /// @dev This protocol fee can be changed by the factory owner in each pool later
  /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
  /// return numerator The numerator of the protocol fee as a ratio of the fee amount
  /// return denominator The denominator of the protocol fee as a ratio of the fee amount
  function feeAmountProtocol(uint24 fee) external view returns (uint8 numerator, uint8 denominator);

  /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
  /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
  /// @param tokenA The contract address of either token0 or token1
  /// @param tokenB The contract address of the other token
  /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
  /// @return pool The pool address
  function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);

  /// @notice Creates a pool for the given two tokens and fee
  /// @param tokenA One of the two tokens in the desired pool
  /// @param tokenB The other of the two tokens in the desired pool
  /// @param fee The desired fee for the pool
  /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
  /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
  /// are invalid.
  /// @return pool The address of the newly created pool
  function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool);

  /// @notice Updates the treasury address
  /// @dev Must be called by the current owner
  /// @param _treasury The new treasury address
  function setTreasury(address _treasury) external;

  /// @notice Toggles the ability to call the `flash` function on KatanaV3Pool
  /// @dev Must be called by the current owner
  function toggleFlashLoanPermission() external;

  /// @notice Enables a fee amount with the given tickSpacing
  /// @dev Fee amounts may never be removed once enabled
  /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
  /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
  /// @param feeProtocolNum The numerator of the protocol fee as a ratio of the fee amount
  /// @param feeProtocolDen The denominator of the protocol fee as a ratio of the fee amount
  function enableFeeAmount(uint24 fee, int24 tickSpacing, uint8 feeProtocolNum, uint8 feeProtocolDen) external;
}
