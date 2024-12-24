import { factoryFixture } from '../../core/shared/fixtures'
import { abi as FACTORY_V2_ABI, bytecode as FACTORY_V2_BYTECODE } from '@uniswap/v2-core/build/UniswapV2Factory.json'
import { Fixture } from 'ethereum-waffle'
import { ethers, waffle } from 'hardhat'
import { KatanaV3Factory, IWETH9, MockTimeSwapRouter, KatanaGovernanceMock } from '../../../typechain'

import WETH9 from '../contracts/WETH9.json'
import { Contract } from '@ethersproject/contracts'
import { constants } from 'ethers'

const wethFixture: Fixture<{ weth9: IWETH9 }> = async ([wallet]) => {
  const weth9 = (await waffle.deployContract(wallet, {
    bytecode: WETH9.bytecode,
    abi: WETH9.abi,
  })) as IWETH9

  return { weth9 }
}

export const v2FactoryFixture: Fixture<{ factory: Contract }> = async ([wallet]) => {
  const factory = await waffle.deployContract(
    wallet,
    {
      bytecode: FACTORY_V2_BYTECODE,
      abi: FACTORY_V2_ABI,
    },
    [constants.AddressZero]
  )

  return { factory }
}

const v3CoreFactoryFixture: Fixture<{ factory: KatanaV3Factory, governance: KatanaGovernanceMock }> = async ([wallet, proxyAdmin, treasury], provider) => {
  return factoryFixture([wallet, proxyAdmin, treasury], provider)
}

export const v3RouterFixture: Fixture<{
  weth9: IWETH9
  factory: KatanaV3Factory
  router: MockTimeSwapRouter
  governance: KatanaGovernanceMock
}> = async ([wallet, proxyAdmin, treasury], provider) => {
  const { weth9 } = await wethFixture([wallet], provider)
  const { factory, governance } = await v3CoreFactoryFixture([wallet, proxyAdmin, treasury], provider)

  const router = (await (await ethers.getContractFactory('MockTimeSwapRouter')).deploy(
    factory.address,
    weth9.address
  )) as MockTimeSwapRouter

  return { factory, weth9, router, governance }
}
