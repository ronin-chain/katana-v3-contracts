# Katana V3 Smart Contracts

This repository contains the smart contracts for Katana V3, a decentralized exchange forked from Uniswap V3 and deployed on the Ronin blockchain.

It includes both core and peripheral contracts. However, the router for swapping tokens, which supports both V2 and V3 pools, is hosted in [a separate repository](https://github.com/ronin-chain/katana-operation-contracts).

## Development

### Prerequisites

To work with this repository, ensure you have the following tools installed:
- Node.js (version 16 or later)
- Yarn or npm
- Hardhat

After cloning the repository, install the required JavaScript dependencies for testing by running:
```
yarn
```

### Compiling

To compile the contracts, run:
```
forge build
```
This will generate the compiled artifacts in the out directory.

### Testing

You can run tests to ensure the contracts work as expected.
```
forge test
```
With Hardhat tests, run:
```
yarn test
```
