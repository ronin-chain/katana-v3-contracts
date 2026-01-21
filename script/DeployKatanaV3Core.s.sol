// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import { Script, console } from "forge-std/Script.sol";
import { KatanaV3Factory } from "src/core/KatanaV3Factory.sol";
import { KatanaV3Pool } from "src/core/KatanaV3Pool.sol";
import { KatanaV3PoolBeacon } from "src/core/KatanaV3PoolBeacon.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

/**
 * @title DeployKatanaV3Core
 * @notice Abstract script to handle the deployment of Katana V3 Core components.
 * Utilizes Beacon Proxy pattern for Pools and Transparent Proxy for the Factory.
 */
abstract contract DeployKatanaV3Core is Script {
    address public proxyAdmin;
    address public governance;
    address public treasury;

    address public poolImplementation;
    address public beacon;
    address public factory;

    /**
     * @dev Validate initial parameters to prevent "dead" deployments.
     */
    function setUp() public virtual {
        require(proxyAdmin != address(0), "Deploy: ProxyAdmin zero address");
        require(governance != address(0), "Deploy: Governance zero address");
        require(treasury != address(0), "Deploy: Treasury zero address");
        
        logParams();
    }

    /**
     * @dev Core deployment logic wrapped in broadcast for ledger/private key signing.
     */
    function run() public virtual {
        vm.startBroadcast();

        // 1. Deploy Pool Implementation (The logic contract)
        poolImplementation = address(new KatanaV3Pool());
        
        // 2. Deploy the Beacon (Points to pool implementation for all future pools)
        beacon = address(new KatanaV3PoolBeacon(poolImplementation));

        // 3. Deploy Factory Implementation
        address factoryImplementation = address(new KatanaV3Factory());

        // 4. Deploy Factory via Transparent Upgradeable Proxy
        // This allows the Factory logic to be upgraded by the proxyAdmin
        factory = address(
            new TransparentUpgradeableProxy(
                factoryImplementation,
                proxyAdmin,
                abi.encodeWithSelector(
                    KatanaV3Factory.initialize.selector, 
                    beacon, 
                    governance, 
                    treasury
                )
            )
        );

        console.log("-----------------------------------------");
        console.log("Pool Implementation: ", poolImplementation);
        console.log("KatanaV3PoolBeacon:  ", beacon);
        console.log("KatanaV3Factory Proxy:", factory);
        console.log("-----------------------------------------");

        vm.stopBroadcast();
    }

    function logParams() internal view virtual {
        console.log("Starting deployment with params:");
        console.log("Governance: ", governance);
        console.log("Treasury:   ", treasury);
        console.log("ProxyAdmin: ", proxyAdmin);
    }
}
