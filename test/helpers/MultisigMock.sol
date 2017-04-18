pragma solidity ^0.4.8;

import '../../contracts/AragonTokenSale.sol';

contract MultisigMock {
  function deployAndSetANT(address sale) {
    ANT token = new ANT(new MiniMeTokenFactory());
    ANPlaceholder networkPlaceholder = new ANPlaceholder(sale, token);
    token.changeController(address(sale));

    AragonTokenSale(sale).setANT(token, networkPlaceholder);
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
