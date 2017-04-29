pragma solidity ^0.4.8;

import '../../contracts/StatusContributionPeriod.sol';

// @dev StatusContributionPeriodMock mocks current block number

contract StatusContributionPeriodMock is StatusContributionPeriod {

  function StatusContributionPeriodMock (
      uint _initialBlock,
      uint _finalBlock,
      address _statusDevMultisig,
      address _communityMultisig,
      uint256 _initialPrice,
      uint256 _finalPrice,
      uint8 _priceStages
  ) StatusContributionPeriod(_initialBlock, _finalBlock, _statusDevMultisig, _communityMultisig, _initialPrice, _finalPrice, _priceStages, computeCap(mock_hiddenCap, mock_capSecret)) {

  }

  function getBlockNumber() constant returns (uint) {
    return mock_blockNumber;
  }

  function setMockedBlockNumber(uint _b) {
    mock_blockNumber = _b;
  }

  function setMockedTotalCollected(uint _totalCollected) {
    totalCollected = _totalCollected;
  }

  uint mock_blockNumber = 1;

  uint public mock_hiddenCap = 100 finney;
  uint public mock_capSecret = 1;
}
