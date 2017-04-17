pragma solidity ^0.4.8;

import '../../contracts/AragonTokenSale.sol';

contract MultisigMock {
  function activateSale(address sale, address factory) {
    ANT token = new ANT(factory);
    ANPlaceholder networkPlaceholder = new ANPlaceholder(sale, token);
    token.changeController(address(this));

    AragonTokenSale(sale).setANT(token, networkPlaceholder);
    AragonTokenSale(sale).activateSale();
  }

  function emergencyStopSale(address sale) {
    AragonTokenSale(sale).emergencyStopSale();
  }

  function restartSale(address sale) {
    AragonTokenSale(sale).restartSale();
  }

  function finalizeSale(address sale) {
    AragonTokenSale(sale).finalizeSale();
  }

  function () payable {}
}
