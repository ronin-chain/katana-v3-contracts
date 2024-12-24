// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "src/core/interfaces/IKatanaV3Pool.sol";
import "@uniswap/lib/contracts/libraries/SafeERC20Namer.sol";

import "./libraries/ChainId.sol";
import "./interfaces/INonfungiblePositionManager.sol";
import "./interfaces/INonfungibleTokenPositionDescriptor.sol";
import "./interfaces/IERC20Metadata.sol";
import "./libraries/PoolAddress.sol";
import "./libraries/NFTDescriptor.sol";
import "./libraries/TokenRatioSortOrder.sol";

/// @title Describes NFT token positions
/// @notice Produces a string containing the data URI for a JSON metadata string
contract NonfungibleTokenPositionDescriptor is INonfungibleTokenPositionDescriptor {
  address private constant USDC = 0x0B7007c13325C48911F73A2daD5FA5dCBf808aDc;
  address private constant WETH = 0xc99a6A985eD2Cac1ef41640596C5A5f9F4E19Ef5;
  address private constant WBTC = 0x7E73630F81647bCFD7B1F2C04c1C662D17d4577e;

  address public immutable WRON;
  /// @dev A null-terminated string
  bytes32 public immutable nativeCurrencyLabelBytes;

  constructor(address _WRON, bytes32 _nativeCurrencyLabelBytes) {
    WRON = _WRON;
    nativeCurrencyLabelBytes = _nativeCurrencyLabelBytes;
  }

  /// @notice Returns the native currency label as a string
  function nativeCurrencyLabel() public view returns (string memory) {
    uint256 len = 0;
    while (len < 32 && nativeCurrencyLabelBytes[len] != 0) {
      len++;
    }
    bytes memory b = new bytes(len);
    for (uint256 i = 0; i < len; i++) {
      b[i] = nativeCurrencyLabelBytes[i];
    }
    return string(b);
  }

  /// @inheritdoc INonfungibleTokenPositionDescriptor
  function tokenURI(INonfungiblePositionManager positionManager, uint256 tokenId)
    external
    view
    override
    returns (string memory)
  {
    (,, address token0, address token1, uint24 fee, int24 tickLower, int24 tickUpper,,,,,) =
      positionManager.positions(tokenId);

    IKatanaV3Pool pool = IKatanaV3Pool(
      PoolAddress.computeAddress(
        positionManager.factory(), PoolAddress.PoolKey({ token0: token0, token1: token1, fee: fee })
      )
    );

    bool _flipRatio = flipRatio(token0, token1, ChainId.get());
    address quoteTokenAddress = !_flipRatio ? token1 : token0;
    address baseTokenAddress = !_flipRatio ? token0 : token1;
    (, int24 tick,,,,,,) = pool.slot0();

    return NFTDescriptor.constructTokenURI(
      NFTDescriptor.ConstructTokenURIParams({
        tokenId: tokenId,
        quoteTokenAddress: quoteTokenAddress,
        baseTokenAddress: baseTokenAddress,
        quoteTokenSymbol: quoteTokenAddress == WRON
          ? nativeCurrencyLabel()
          : SafeERC20Namer.tokenSymbol(quoteTokenAddress),
        baseTokenSymbol: baseTokenAddress == WRON ? nativeCurrencyLabel() : SafeERC20Namer.tokenSymbol(baseTokenAddress),
        quoteTokenDecimals: IERC20Metadata(quoteTokenAddress).decimals(),
        baseTokenDecimals: IERC20Metadata(baseTokenAddress).decimals(),
        flipRatio: _flipRatio,
        tickLower: tickLower,
        tickUpper: tickUpper,
        tickCurrent: tick,
        tickSpacing: pool.tickSpacing(),
        fee: fee,
        poolAddress: address(pool)
      })
    );
  }

  function flipRatio(address token0, address token1, uint256 chainId) public view returns (bool) {
    return tokenRatioPriority(token0, chainId) > tokenRatioPriority(token1, chainId);
  }

  function tokenRatioPriority(address token, uint256 chainId) public view returns (int256) {
    if (token == WRON) {
      return TokenRatioSortOrder.DENOMINATOR;
    }
    if (chainId == 2020) {
      if (token == USDC) {
        return TokenRatioSortOrder.NUMERATOR_MOST;
      } else if (token == WETH) {
        return TokenRatioSortOrder.NUMERATOR_MORE;
      } else if (token == WBTC) {
        return TokenRatioSortOrder.DENOMINATOR_MOST;
      } else {
        return 0;
      }
    }
    return 0;
  }
}
