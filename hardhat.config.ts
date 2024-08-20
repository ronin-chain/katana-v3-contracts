import "@nomicfoundation/hardhat-foundry";
import 'hardhat-typechain'
import '@nomiclabs/hardhat-ethers'
import '@nomiclabs/hardhat-waffle'
import '@nomiclabs/hardhat-etherscan'
import {
	HardhatUserConfig,
	NetworkUserConfig,
} from "hardhat/types";
import * as dotenv from 'dotenv';

dotenv.config();

const { TESTNET_URL, MAINNET_URL } = process.env;

const testnet: NetworkUserConfig = {
	chainId: 2021,
	url: TESTNET_URL || "https://saigon-testnet.roninchain.com/rpc",
};

const mainnet: NetworkUserConfig = {
	chainId: 2020,
	url: MAINNET_URL || "https://api.roninchain.com/rpc",
};

const config: HardhatUserConfig = {
	paths: {
		sources: "./src",
	},

	networks: {
		"ronin-testnet": testnet,
		"ronin-mainnet": mainnet,
	},

	solidity: {
    version: '0.7.6',
    settings: {
      optimizer: {
        enabled: true,
        runs: 250,
      },
    },
  },
};

export default config;
