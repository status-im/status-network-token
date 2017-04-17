pragma solidity ^0.4.8;

import '../../contracts/AragonTokenSale.sol';

contract MultisigMock {
  function activateSale(address sale, address factory) {
    ANT token = new ANT(factory);
    ANPlaceholder networkPlaceholder = new ANPlaceholder(sale, token);
    token.changeController(address(sale));

    AragonTokenSale(sale).setANT(token, networkPlaceholder);
    activateSale(sale);
  }

  function activateSale(address sale) {
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

  function deployNetwork(address sale, address network) {
    AragonTokenSale(sale).deployNetwork(network);
  }

  function () payable {}
}
