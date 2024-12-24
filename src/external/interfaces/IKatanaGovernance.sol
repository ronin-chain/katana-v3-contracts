// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;
pragma abicoder v2;

interface IKatanaGovernance {
  struct Permission {
    // The timestamp until the whitelist is ended.
    // 0 means the whitelist is disabled.
    uint40 whitelistUntil;
    // The mapping of the allowed addresses in the whitelist stage.
    mapping(address => bool) allowed;
  }

  /// @dev Emitted when the router address is updated.
  event RouterUpdated(address indexed by, address indexed oldRouter, address indexed newRouter);
  /// @dev Emitted when the factory address is updated.
  event FactoryUpdated(address indexed by, address factory);
  /// @dev Emitted when the permission of a token is updated.
  event PermissionUpdated(
    address indexed by, address indexed token, uint40 whitelistUntil, address[] allowed, bool[] statuses
  );
  /// @dev Emitted when allowed actor list is updated.
  event AllowedActorUpdated(address indexed actor, bool allowed);

  /**
   * @dev Sets the router address.
   *
   * - Requirements: Caller must be the owner.
   *
   * @param router The address of the router.
   */
  function setRouter(address router) external;

  /**
   * @dev Sets an address is allowed/disallowed to skip authorization checks.
   * To check if an address is allowed, see `isAllowedActor` function.
   *
   * - Requirements: Caller must be the owner.
   *
   * @param actor The address to be allowed/disallowed.
   * @param allowed True if the address is allowed, otherwise false.
   */
  function setAllowedActor(address actor, bool allowed) external;

  /**
   * @notice Toggles the ability to call the `flash` function on KatanaV3Pool
   *
   * - Requirements: Caller must be the owner.
   */
  function toggleFlashLoanPermission() external;

  /**
   * @notice Enables a fee amount with the given tickSpacing for KatanaV3Factory
   * @dev Fee amounts may never be removed once enabled. Caller must be the owner.
   *
   * @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
   * @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
   * @param feeProtocolNum The numerator of the protocol fee as a ratio of the fee amount
   * @param feeProtocolDen The denominator of the protocol fee as a ratio of the fee amount
   */
  function enableFeeAmount(uint24 fee, int24 tickSpacing, uint8 feeProtocolNum, uint8 feeProtocolDen) external;

  /**
   * @dev Sets the permission of a token.
   *
   * - Requirements: Caller must be the owner.
   *
   * @param token The address of the token.
   * @param whitelistUntil The end of the whitelist duration in seconds.
   * @param alloweds The addresses to be allowed.
   * @param statuses The statuses of the addresses.
   */
  function setPermission(address token, uint40 whitelistUntil, address[] calldata alloweds, bool[] calldata statuses)
    external;

  /**
   * @dev Creates a pair of tokens and sets the permission.
   *
   * - Requirements: Caller must be the owner.
   *
   * @param tokenA The address of the first token.
   * @param tokenB The address of the second token.
   * @param whitelistUntil The end of the whitelist duration in seconds.
   * @param alloweds The addresses to be allowed.
   * @param statuses The whitelist statuses of the addresses.
   * @return pair The address of the pair.
   */
  function createPairAndSetPermission(
    address tokenA,
    address tokenB,
    uint40 whitelistUntil,
    address[] calldata alloweds,
    bool[] calldata statuses
  ) external returns (address pair);

  /**
   * @notice Gets the current router address.
   */
  function getRouter() external view returns (address);

  /**
   * @notice Gets the Katana V3 nonfungible position manager address.
   */
  function getPositionManager() external view returns (address);

  /**
   * @notice Whether the account is always skipped from authorization checks.
   * @dev See `isAuthorized` function.
   */
  function isAllowedActor(address account) external view returns (bool);

  /**
   * @notice Checks if an account is authorized to interact with a token.
   *
   * @param token The address of the token.
   * @param account The address of the account.
   * @return True if the account is authorized, otherwise false.
   */
  function isAuthorized(address token, address account) external view returns (bool);

  /**
   * @notice Gets the Katana V3 factory address.
   */
  function getV3Factory() external view returns (address);

  /**
   * @dev Gets the Katana V2 factory address.
   */
  function getV2Factory() external view returns (address);

  /**
   * @notice Gets the whitelist duration of a token.
   *
   * @param token The address of the token.
   * @return The whitelist duration.
   */
  function getWhitelistUntil(address token) external view returns (uint40);

  /**
   * @notice Gets the whitelist information of many tokens.
   *
   * @return tokens The addresses of the tokens.
   * @return whitelistUntils The array of whitelist until timestamps.
   */
  function getManyTokensWhitelistInfo()
    external
    view
    returns (address[] memory tokens, uint40[] memory whitelistUntils);

  /**
   * @notice Gets all whitelisted tokens for given account.
   *
   * @param account The address of the account.
   * @return tokens The addresses of the tokens.
   * @return whitelistUntils The array of whitelist until timestamps.
   */
  function getWhitelistedTokensFor(address account)
    external
    view
    returns (address[] memory tokens, uint40[] memory whitelistUntils);

  /**
   * @notice Checks if an account is authorized to interact with a path tokens.
   *
   * @param tokens The path to swap on.
   * @param account The address of the account.
   * @return False if exists one token that the account is not authorized, otherwise true.
   */
  function isAuthorized(address[] calldata tokens, address account) external view returns (bool);
}
