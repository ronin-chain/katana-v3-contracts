// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <0.9.0;

import "../interfaces/IKatanaGovernance.sol";

library AuthorizationLib {
  function checkPair(address governance, address token0, address token1) internal view {
    address[] memory tokens = new address[](2);
    tokens[0] = token0;
    tokens[1] = token1;
    require(IKatanaGovernance(governance).isAuthorized(tokens, msg.sender), "UA");
  }
}
