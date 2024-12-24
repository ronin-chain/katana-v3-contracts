import { abi as POOL_ABI } from '../../../artifacts/src/core/KatanaV3Pool.sol/KatanaV3Pool.json'
import { Contract, Wallet } from 'ethers'
import { IKatanaV3Pool } from '../../../typechain'

export default function poolAtAddress(address: string, wallet: Wallet): IKatanaV3Pool {
  return new Contract(address, POOL_ABI, wallet) as IKatanaV3Pool
}
