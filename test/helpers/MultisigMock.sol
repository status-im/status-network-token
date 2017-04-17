pragma solidity ^0.4.8;

import '../../contracts/AragonTokenSale.sol';

contract MultisigMock {
  function activateSale(address sale, address factory) {
    AragonTokenSale(sale).deployANT(factory);
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
