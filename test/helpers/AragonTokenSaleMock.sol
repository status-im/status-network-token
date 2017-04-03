pragma solidity ^0.4.8;

import '../../contracts/AragonTokenSale.sol';

// @dev AragonTokenSaleMock mocks current block number

contract AragonTokenSaleMock is AragonTokenSale {

  function AragonTokenSaleMock (
      uint _initialBlock,
      uint _finalBlock,
      address _aragonDevMultisig,
      address _communityMultisig,
      uint256 _initialPrice,
      uint256 _finalPrice,
      uint8 _priceStages
  ) AragonTokenSale(_initialBlock, _finalBlock, _aragonDevMultisig, _communityMultisig, _initialPrice, _finalPrice, _priceStages) {

  }

  function getBlockNumber() constant returns (uint) {
    return mockedBlockNumber;
  }

  function setMockedBlockNumber(uint _b) {
    mockedBlockNumber = _b;
  }

  uint mockedBlockNumber = 1;
}
