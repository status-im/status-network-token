pragma solidity ^0.4.8;

import '../../contracts/MiniMeToken.sol';
import '../../contracts/AragonTokenSale.sol';

// @dev AragonTokenSaleMock for ERC20 tests purpose.
// As it also deploys MiniMeTokenFactory, nonce will be broken.

contract AragonTokenSaleMock is AragonTokenSale {
  function AragonTokenSaleMock(address initialAccount, uint initialBalance)
    AragonTokenSale(block.number + 10, block.number + 100, msg.sender, 0xdead, 1 wei, 2 wei, 2)
    {
    deployANT(new MiniMeTokenFactory(), true);
    token.generateTokens(initialAccount, initialBalance);
  }
}
