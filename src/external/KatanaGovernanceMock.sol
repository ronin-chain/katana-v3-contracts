// // SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IKatanaGovernance.sol";

contract KatanaGovernanceMock is IKatanaGovernance {
  address private _router;
  address private _v3Factory;
  address private _positionManager;
  bool private immutable _defaultPermission;
  mapping(address => mapping(address => uint256)) private _permission;

  constructor(bool defaultPermission) {
    _defaultPermission = defaultPermission;
  }

  function allow(address token, address account) external {
    _permission[token][account] = 1;
  }

  function disallow(address token, address account) external {
    _permission[token][account] = 2;
  }

  function setRouter(address router) external override {
    _router = router;
  }

  function setPositionManager(address positionManager) external {
    _positionManager = positionManager;
  }

  function getRouter() external view override returns (address) {
    return _router;
  }

  function getV3Factory() external view override returns (address) {
    return _v3Factory;
  }

  function getPositionManager() external view override returns (address) {
    return _positionManager;
  }

  function isAuthorized(address[] memory tokens, address account) external view override returns (bool) {
    for (uint256 i = 0; i < tokens.length; ++i) {
      if (!isAuthorized(tokens[i], account)) {
        return false;
      }
    }
    return true;
  }

  function isAuthorized(address token, address account) public view override returns (bool) {
    return _permission[token][account] == 1 || (_defaultPermission && _permission[token][account] == 0);
  }

  function setV3Factory(address factory) external {
    _v3Factory = factory;
  }

  function setAllowedActor(address, bool) external pure override {
    revert("not implemented");
  }

  function setPermission(address, uint40, address[] memory, bool[] memory) external pure override {
    revert("not implemented");
  }

  function createPairAndSetPermission(address, address, uint40, address[] memory, bool[] memory)
    external
    pure
    override
    returns (address)
  {
    revert("not implemented");
  }

  function toggleFlashLoanPermission() external pure override {
    revert("not implemented");
  }

  function enableFeeAmount(uint24, int24, uint8, uint8) external pure override {
    revert("not implemented");
  }

  function isAllowedActor(address) external pure override returns (bool) {
    revert("not implemented");
  }

  function getV2Factory() external pure override returns (address) {
    revert("not implemented");
  }

  function getManyTokensWhitelistInfo() external pure override returns (address[] memory, uint40[] memory) {
    revert("not implemented");
  }

  function getWhitelistUntil(address) external pure override returns (uint40) {
    revert("not implemented");
  }

  function getWhitelistedTokensFor(address) external pure override returns (address[] memory, uint40[] memory) {
    revert("not implemented");
  }
}
