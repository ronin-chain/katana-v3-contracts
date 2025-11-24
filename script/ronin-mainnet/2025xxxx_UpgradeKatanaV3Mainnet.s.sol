// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import { KatanaV3Pool } from "src/core/KatanaV3Pool.sol";
import { KatanaV3Factory } from "src/core/KatanaV3Factory.sol";
import { KatanaV3PoolBeacon } from "src/core/KatanaV3PoolBeacon.sol";
import { NonfungiblePositionManager } from "src/periphery/NonfungiblePositionManager.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/UpgradeableBeacon.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/ProxyAdmin.sol";
import { V3Migrator } from "src/periphery/V3Migrator.sol";

contract Migration__2025xxxx_UpgradeKatanaV3Mainnet is Script {
  address proxyAdmin = 0xA3e7d085E65CB0B916f6717da876b7bE5cC92f03;

  address positionDescriptor = 0x8766648aA6586cC7Cd2cDb2Bd911eec78Cab89Ea;
  address positionManager = 0x7cF0fb64d72b733695d77d197c664e90D07cF45A;
  address factory = 0x1f0B70d9A137e3cAEF0ceAcD312BC5f81Da0cC0c;
  address poolBeacon = 0x4c4C0ae2fa6f117dC4a1f0495Cbfc902e78cDF31;
  address governance = 0x2C1726346d83cBF848bD3C2B208ec70d32a9E44a;

  NonfungiblePositionManager pmContract = NonfungiblePositionManager(payable(positionManager));
  KatanaV3Factory factoryContract = KatanaV3Factory(factory);
  KatanaV3PoolBeacon poolBeaconContract = KatanaV3PoolBeacon(poolBeacon);

  address deployer;
  address masterOwner; // safe wallet
  address weth9;

  // PositionManager state
  string pm_name;
  string pm_symbol;
  uint256 pm_totalSupply;
  bytes32 pm_DOMAIN_SEPARATOR;
  bytes32 pm_PERMIT_TYPEHASH;

  // Factory state
  address f_treasury;
  address f_owner;
  bool f_flashLoanEnabled;

  // pool beacon state
  bytes pb_POOL_PROXY_INIT_CODE;
  bytes32 pb_POOL_PROXY_INIT_CODE_HASH;
  address pb_owner;

  function setUp() public {
    masterOwner = ProxyAdmin(proxyAdmin).owner();
    weth9 = pmContract.WETH9();

    require(pmContract.factory() == factory, "PositionManager factory mismatch");
    require(factoryContract.beacon() == poolBeacon, "Factory beacon mismatch");
    require(pmContract.governance() == governance, "PositionManager governance mismatch");
  }

  function run() public {
    deployer = vm.rememberKey(vm.envUint("MAINNET_PK"));
    require(deployer != masterOwner, "Deployer cannot be master owner in mainnet");

    console.log("=== Katana V3 Mainnet Upgrade ===");
    console.log("Deployer:", deployer);
    console.log("Master Owner (Safe):", masterOwner);
    console.log("");

    vm.broadcast(deployer);
    address v3migrator = address(new V3Migrator(factory, weth9, positionManager));
    console.log("  V3Migrator deployed:", v3migrator);

    upgradePositionManager();
    upgradeFactory();
    upgradePool();

    console.log("=== Upgrade simulation completed successfully! ===");
  }

  function upgradePositionManager() internal {
    /// Pre upgrade
    pm_name = pmContract.name();
    pm_symbol = pmContract.symbol();
    pm_totalSupply = pmContract.totalSupply();
    pm_DOMAIN_SEPARATOR = pmContract.DOMAIN_SEPARATOR();
    pm_PERMIT_TYPEHASH = pmContract.PERMIT_TYPEHASH();

    /// Upgrade
    vm.broadcast(deployer);
    address newPositionManagerLogic = address(new NonfungiblePositionManager(factory, weth9, positionDescriptor));
    console.log("  [PositionManager] new implementation:", newPositionManagerLogic);
    bytes memory positionManagerUpgradeCalldata =
      abi.encodeWithSelector(ProxyAdmin.upgrade.selector, positionManager, newPositionManagerLogic);
    safeTransaction({ name: "PositionManager", from: masterOwner, to: proxyAdmin, data: positionManagerUpgradeCalldata });

    /// Post upgrade
    requireAndLog(
      ProxyAdmin(proxyAdmin).getProxyImplementation(TransparentUpgradeableProxy(payable(positionManager)))
        == newPositionManagerLogic,
      "[PositionManager] check implementation"
    );
    requireAndLog(
      keccak256(abi.encodePacked(pmContract.name())) == keccak256(abi.encodePacked(pm_name)),
      "[PositionManager] check name"
    );
    requireAndLog(
      keccak256(abi.encodePacked(pmContract.symbol())) == keccak256(abi.encodePacked(pm_symbol)),
      "[PositionManager] check symbol"
    );
    requireAndLog(pmContract.totalSupply() == pm_totalSupply, "[PositionManager] check total supply");
    requireAndLog(pmContract.DOMAIN_SEPARATOR() == pm_DOMAIN_SEPARATOR, "[PositionManager] check DOMAIN_SEPARATOR");
    requireAndLog(pmContract.PERMIT_TYPEHASH() == pm_PERMIT_TYPEHASH, "[PositionManager] check PERMIT_TYPEHASH");
    console.log("");
  }

  function upgradeFactory() internal {
    /// Pre upgrade
    f_treasury = factoryContract.treasury();
    f_owner = factoryContract.owner();
    f_flashLoanEnabled = factoryContract.flashLoanEnabled();

    /// Upgrade
    vm.broadcast(deployer);
    address newFactoryLogic = address(new KatanaV3Factory());
    console.log("  [Factory] new implementation:", newFactoryLogic);
    bytes memory factoryUpgradeCalldata = abi.encodeWithSelector(ProxyAdmin.upgrade.selector, factory, newFactoryLogic);
    safeTransaction({ name: "Factory", from: masterOwner, to: proxyAdmin, data: factoryUpgradeCalldata });

    /// Post upgrade
    requireAndLog(
      ProxyAdmin(proxyAdmin).getProxyImplementation(TransparentUpgradeableProxy(payable(factory))) == newFactoryLogic,
      "[Factory] check implementation"
    );
    requireAndLog(factoryContract.treasury() == f_treasury, "[Factory] check treasury");
    requireAndLog(factoryContract.owner() == f_owner, "[Factory] check owner");
    requireAndLog(factoryContract.flashLoanEnabled() == f_flashLoanEnabled, "[Factory] check flash loan enabled");
  }

  function upgradePool() internal {
    /// Pre upgrade
    pb_POOL_PROXY_INIT_CODE = poolBeaconContract.POOL_PROXY_INIT_CODE();
    pb_POOL_PROXY_INIT_CODE_HASH = poolBeaconContract.POOL_PROXY_INIT_CODE_HASH();
    pb_owner = poolBeaconContract.owner();

    /// Upgrade
    vm.broadcast(deployer);
    address newPoolLogic = address(new KatanaV3Pool());
    console.log("  [Pool] new implementation:", newPoolLogic);
    bytes memory poolUpgradeCalldata = abi.encodeWithSelector(UpgradeableBeacon.upgradeTo.selector, newPoolLogic);
    safeTransaction({ name: "Pool", from: masterOwner, to: poolBeacon, data: poolUpgradeCalldata });

    /// Post upgrade
    requireAndLog(poolBeaconContract.implementation() == newPoolLogic, "[Pool] check implementation");
    requireAndLog(
      keccak256(poolBeaconContract.POOL_PROXY_INIT_CODE()) == keccak256(pb_POOL_PROXY_INIT_CODE),
      "[Pool] check pool proxy init code"
    );
    requireAndLog(
      poolBeaconContract.POOL_PROXY_INIT_CODE_HASH() == pb_POOL_PROXY_INIT_CODE_HASH,
      "[Pool] check pool proxy init code hash"
    );
    requireAndLog(poolBeaconContract.owner() == pb_owner, "[Pool] check pool beacon owner");
  }

  function safeTransaction(string memory name, address from, address to, bytes memory data) internal {
    logSafeTransaction(name, from, to, data);
    vm.prank(from);
    (bool success,) = address(to).call(data);
    require(success, "Safe transaction failed");
    console.log("  [%s] simulation successful: \xE2\x9C\x85", name);
  }

  /// @dev Helper function to log upgrade transaction details
  function logSafeTransaction(string memory name, address from, address to, bytes memory data) internal pure {
    console.log("  [%s] from:     ", name, from);
    console.log("  [%s] to:       ", name, to);
    console.log("  [%s] calldata: ", name, vm.toString(data));
  }

  function requireAndLog(bool condition, string memory message) internal pure {
    require(condition, message);
    console.log("  %s: \xE2\x9C\x85", message);
  }
}
