import { Wallet } from 'ethers'
import { ethers, waffle, network } from 'hardhat'
import { KatanaV3Factory } from '../../typechain/KatanaV3Factory'
import { KatanaGovernanceMock } from '../../typechain/KatanaGovernanceMock'
import { expect } from './shared/expect'
import { factoryFixture } from './shared/fixtures'
import { bytecode as poolProxyBytecode } from '../../out/KatanaV3PoolProxy.sol/KatanaV3PoolProxy.json'
import snapshotGasCost from './shared/snapshotGasCost'

import { FeeAmount, getCreate2Address, TICK_SPACINGS } from './shared/utilities'

const { constants } = ethers

const TEST_ADDRESSES: [string, string] = [
  '0x1000000000000000000000000000000000000000',
  '0x2000000000000000000000000000000000000000',
]

const createFixtureLoader = waffle.createFixtureLoader

describe('KatanaV3Factory', () => {
  let deployer: Wallet, proxyAdmin: Wallet, treasury: Wallet, positionManager: Wallet, other: Wallet

  let factory: KatanaV3Factory
  let governance: KatanaGovernanceMock
  let poolBytecode: string

  let loadFixture: ReturnType<typeof createFixtureLoader>
  before('create fixture loader', async () => {
    [deployer, proxyAdmin, treasury, positionManager, other] = await (ethers as any).getSigners()
    loadFixture = createFixtureLoader([deployer, proxyAdmin, treasury, other])
  })

  before('load pool bytecode', async () => {
    poolBytecode = poolProxyBytecode.object
  })

  beforeEach('deploy factory', async () => {
    ({ factory, governance } = await loadFixture(factoryFixture))
    await governance.setPositionManager(positionManager.address)
  })

  it('owner is governance', async () => {
    expect(await factory.owner()).to.eq(governance.address)
  })

  it('factory bytecode size', async () => {
    expect(((await waffle.provider.getCode(factory.address)).length - 2) / 2).to.matchSnapshot()
  })

  it('pool bytecode size', async () => {
    await factory.connect(positionManager).createPool(TEST_ADDRESSES[0], TEST_ADDRESSES[1], FeeAmount.MEDIUM)
    const poolAddress = getCreate2Address(factory.address, TEST_ADDRESSES, FeeAmount.MEDIUM, poolBytecode)
    expect(((await waffle.provider.getCode(poolAddress)).length - 2) / 2).to.matchSnapshot()
  })

  it('initial enabled fee amounts', async () => {
    expect(await factory.feeAmountTickSpacing(FeeAmount.LOW)).to.eq(TICK_SPACINGS[FeeAmount.LOW])
    expect(await factory.feeAmountTickSpacing(FeeAmount.MEDIUM)).to.eq(TICK_SPACINGS[FeeAmount.MEDIUM])
    expect(await factory.feeAmountTickSpacing(FeeAmount.HIGH)).to.eq(TICK_SPACINGS[FeeAmount.HIGH])
  })

  async function createAndCheckPool(
    tokens: [string, string],
    feeAmount: FeeAmount,
    tickSpacing: number = TICK_SPACINGS[feeAmount]
  ) {
    // prank postion manager to be able to create pools
    factory = factory.connect(positionManager)

    const create2Address = getCreate2Address(factory.address, tokens, feeAmount, poolBytecode)
    const create = factory.createPool(tokens[0], tokens[1], feeAmount)

    await expect(create)
      .to.emit(factory, 'PoolCreated')
      .withArgs(TEST_ADDRESSES[0], TEST_ADDRESSES[1], feeAmount, tickSpacing, create2Address)

    await expect(factory.createPool(tokens[0], tokens[1], feeAmount)).to.be.reverted
    await expect(factory.createPool(tokens[1], tokens[0], feeAmount)).to.be.reverted
    expect(await factory.getPool(tokens[0], tokens[1], feeAmount), 'getPool in order').to.eq(create2Address)
    expect(await factory.getPool(tokens[1], tokens[0], feeAmount), 'getPool in reverse').to.eq(create2Address)

    const poolContractFactory = await ethers.getContractFactory('KatanaV3Pool')
    const pool = poolContractFactory.attach(create2Address)
    expect(await pool.factory(), 'pool factory address').to.eq(factory.address)
    expect(await pool.token0(), 'pool token0').to.eq(TEST_ADDRESSES[0])
    expect(await pool.token1(), 'pool token1').to.eq(TEST_ADDRESSES[1])
    expect(await pool.fee(), 'pool fee').to.eq(feeAmount)
    expect(await pool.tickSpacing(), 'pool tick spacing').to.eq(tickSpacing)
  }

  describe('#createPool', () => {
    it('succeeds for low fee pool', async () => {
      await createAndCheckPool(TEST_ADDRESSES, FeeAmount.LOW)
    })

    it('succeeds for medium fee pool', async () => {
      await createAndCheckPool(TEST_ADDRESSES, FeeAmount.MEDIUM)
    })
    it('succeeds for high fee pool', async () => {
      await createAndCheckPool(TEST_ADDRESSES, FeeAmount.HIGH)
    })

    it('succeeds if tokens are passed in reverse', async () => {
      await createAndCheckPool([TEST_ADDRESSES[1], TEST_ADDRESSES[0]], FeeAmount.MEDIUM)
    })

    it('fails if token a == token b', async () => {
      await expect(factory.createPool(TEST_ADDRESSES[0], TEST_ADDRESSES[0], FeeAmount.LOW)).to.be.reverted
    })

    it('fails if token a is 0 or token b is 0', async () => {
      await expect(factory.createPool(TEST_ADDRESSES[0], constants.AddressZero, FeeAmount.LOW)).to.be.reverted
      await expect(factory.createPool(constants.AddressZero, TEST_ADDRESSES[0], FeeAmount.LOW)).to.be.reverted
      await expect(factory.createPool(constants.AddressZero, constants.AddressZero, FeeAmount.LOW)).to.be.revertedWith(
        ''
      )
    })

    it('fails if fee amount is not enabled', async () => {
      await expect(factory.createPool(TEST_ADDRESSES[0], TEST_ADDRESSES[1], 250)).to.be.reverted
    })

    it('gas', async () => {
      await snapshotGasCost(factory.connect(positionManager).createPool(TEST_ADDRESSES[0], TEST_ADDRESSES[1], FeeAmount.MEDIUM))
    })
  })

  async function prankGovernance() {
    await network.provider.request({
      method: 'hardhat_impersonateAccount',
      params: [governance.address],
    })
    await network.provider.send("hardhat_setBalance", [
      governance.address,
      "0xDE0B6B3A7640000", // 1 ETH
    ]);
    const signer = await ethers.getSigner(governance.address)
    factory = await factory.connect(signer)
  }

  describe('#enableFeeAmount', () => {
    beforeEach("prank the governance", prankGovernance)

    it('fails if caller is not owner', async () => {
      await expect(factory.connect(other).enableFeeAmount(500, 10, 25, 50)).to.be.reverted
    })
    it('fails if fee is too great', async () => {
      await expect(factory.enableFeeAmount(1000000, 10, 5, 10)).to.be.reverted
    })
    it('fails if tick spacing is too small', async () => {
      await expect(factory.enableFeeAmount(100, 0, 5, 10)).to.be.reverted
    })
    it('fails if tick spacing is too large', async () => {
      await expect(factory.enableFeeAmount(500, 16834, 25, 50)).to.be.reverted
    })
    it('fails if already initialized', async () => {
      await factory.enableFeeAmount(500, 5, 25, 50)
      await expect(factory.enableFeeAmount(500, 10, 25, 50)).to.be.reverted
    })
    it('sets the fee amount in the mapping', async () => {
      await factory.enableFeeAmount(500, 5, 25, 50)
      expect(await factory.feeAmountTickSpacing(500)).to.eq(5)
    })
    it('emits an event', async () => {
      await expect(factory.enableFeeAmount(500, 10, 25, 50)).to.emit(factory, 'FeeAmountEnabled').withArgs(500, 10, 25, 50)
    })
    it('enables pool creation', async () => {
      await factory.enableFeeAmount(250, 15, 10, 25)
      await createAndCheckPool([TEST_ADDRESSES[0], TEST_ADDRESSES[1]], 250, 15)
    })
  })
})
