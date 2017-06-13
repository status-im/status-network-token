pragma solidity ^0.4.8;

import '../../contracts/SGT.sol';

// @dev AragonTokenSaleMock mocks current block number

contract SGTMock is SGT {

    function SGTMock(address _tokenFactory) SGT(_tokenFactory) {}

    function getBlockNumber() internal constant returns (uint) {
        return mock_blockNumber;
    }

    function setMockedBlockNumber(uint _b) public {
        mock_blockNumber = _b;
    }

    uint mock_blockNumber = 1;
}
