import { BigNumber, constants } from "ethers";
import { ethers } from "hardhat";
import { MockTimeKatanaV3Pool } from '../../../typechain/MockTimeKatanaV3Pool'
import { TestERC20 } from '../../../typechain/TestERC20'
import { KatanaV3Factory } from '../../../typechain/KatanaV3Factory'
import { TestKatanaV3Callee } from '../../../typechain/TestKatanaV3Callee'
import { TestKatanaV3Router } from '../../../typechain/TestKatanaV3Router'
import { MockTimeKatanaV3PoolDeployer } from '../../../typechain/MockTimeKatanaV3PoolDeployer'
import { KatanaGovernanceMock } from '../../../typechain/KatanaGovernanceMock'

import { Fixture, loadFixture } from "ethereum-waffle";
import { expect } from "chai";
interface GovernanceFixture {
  governance: KatanaGovernanceMock;
}

async function governanceFixture(): Promise<GovernanceFixture> {
  const governanceFactory = await ethers.getContractFactory(
    "KatanaGovernanceMock"
  );
  const governance = (await governanceFactory.deploy(true)) as KatanaGovernanceMock;

  return { governance };
}

interface FactoryFixture {
  factory: KatanaV3Factory;
  governance: KatanaGovernanceMock
}

export const factoryFixture: Fixture<FactoryFixture> = async function ([
  deployer,
  proxyAdmin,
  treasury,
]): Promise<FactoryFixture> {
  const { governance } = await loadFixture(governanceFixture);

  // Deploy the KatanaV3Pool implementation contract
  const poolImplementationFactory = await ethers.getContractFactory("KatanaV3Pool", deployer)
  const poolImplementation = await poolImplementationFactory.deploy()
  await poolImplementation.deployed()

  // Deploy the KatanaV3PoolBeacon contract
  const beaconFactory = await ethers.getContractFactory("KatanaV3PoolBeacon", deployer)
  const beacon = await beaconFactory.deploy(poolImplementation.address);
  await beacon.deployed()

  // Deploy the KatanaV3Factory implementation contract
  const factoryImplementationFactory = await ethers.getContractFactory("KatanaV3Factory", deployer)
  const factoryImplementation = await factoryImplementationFactory.deploy()
  await factoryImplementation.deployed()

  // Deploy the KatanaV3Factory proxy contract
  const factoryProxyFactory = await ethers.getContractFactory("TransparentUpgradeableProxy", deployer)
  const factoryProxy = await factoryProxyFactory.deploy(
    factoryImplementation.address,
    proxyAdmin.address,
    factoryImplementation.interface.encodeFunctionData("initialize", [beacon.address, governance.address, treasury.address]) // owner is set to governance
  )
  await factoryProxy.deployed()
  const factory = factoryImplementation.attach(factoryProxy.address) as KatanaV3Factory;

  return { factory, governance }
}

interface TokensFixture {
  token0: TestERC20
  token1: TestERC20
  token2: TestERC20
}

async function tokensFixture(): Promise<TokensFixture> {
  const tokenFactory = await ethers.getContractFactory('TestERC20')
  const tokenA = (await tokenFactory.deploy(BigNumber.from(2).pow(255))) as TestERC20
  const tokenB = (await tokenFactory.deploy(BigNumber.from(2).pow(255))) as TestERC20
  const tokenC = (await tokenFactory.deploy(BigNumber.from(2).pow(255))) as TestERC20

  const [token0, token1, token2] = [tokenA, tokenB, tokenC].sort((tokenA, tokenB) =>
    tokenA.address.toLowerCase() < tokenB.address.toLowerCase() ? -1 : 1
  )

  return { token0, token1, token2 }
}

type TokensAndFactoryFixture = FactoryFixture & TokensFixture

interface PoolFixture extends TokensAndFactoryFixture {
  swapTargetCallee: TestKatanaV3Callee
  swapTargetRouter: TestKatanaV3Router
  createPool(
    fee: number,
    tickSpacing: number,
    firstToken?: TestERC20,
    secondToken?: TestERC20
  ): Promise<MockTimeKatanaV3Pool>
}

// Monday, October 5, 2020 9:00:00 AM GMT-05:00
export const TEST_POOL_START_TIME = 1601906400

export const poolFixture: Fixture<PoolFixture> = async function ([
  deployer,
  proxyAdmin,
  treasury,
], provider): Promise<PoolFixture> {
  const { factory, governance } = await factoryFixture([deployer, proxyAdmin, treasury], provider)
  const { token0, token1, token2 } = await tokensFixture()

  const MockTimeKatanaV3PoolDeployerFactory = await ethers.getContractFactory('MockTimeKatanaV3PoolDeployer')
  const MockTimeKatanaV3PoolFactory = await ethers.getContractFactory('MockTimeKatanaV3Pool')

  const calleeContractFactory = await ethers.getContractFactory('TestKatanaV3Callee')
  const routerContractFactory = await ethers.getContractFactory('TestKatanaV3Router')

  const swapTargetCallee = (await calleeContractFactory.deploy()) as TestKatanaV3Callee
  const swapTargetRouter = (await routerContractFactory.deploy()) as TestKatanaV3Router

  return {
    token0,
    token1,
    token2,
    factory,
    governance,
    swapTargetCallee,
    swapTargetRouter,
    createPool: async (fee, tickSpacing, firstToken = token0, secondToken = token1) => {
      const mockTimePoolDeployer = (await MockTimeKatanaV3PoolDeployerFactory.deploy()) as MockTimeKatanaV3PoolDeployer
      const tx = await mockTimePoolDeployer.deploy(
        factory.address,
        firstToken.address,
        secondToken.address,
        fee,
        tickSpacing
      )

      const receipt = await tx.wait()
      const poolAddress = receipt.events?.[0].args?.pool as string
      return MockTimeKatanaV3PoolFactory.attach(poolAddress) as MockTimeKatanaV3Pool
    }
  }
}
