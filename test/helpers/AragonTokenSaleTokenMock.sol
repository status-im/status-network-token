pragma solidity ^0.4.8;

import '../../contracts/AragonTokenSale.sol';

// @dev AragonTokenSaleTokenMock for ERC20 tests purpose.
// As it also deploys MiniMeTokenFactory, nonce will be broken.

contract AragonTokenSaleTokenMock is AragonTokenSale {
  function AragonTokenSaleTokenMock(address initialAccount, uint initialBalance)
    AragonTokenSale(block.number + 10, block.number + 100, msg.sender, 0xdead, 2, 1, 2)
    {
    deployANT(new MiniMeTokenFactory(), true);
    token.generateTokens(initialAccount, initialBalance);
  }
}
