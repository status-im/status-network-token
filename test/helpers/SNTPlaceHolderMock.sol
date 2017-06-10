pragma solidity ^0.4.8;

import '../../contracts/SNTPlaceHolder.sol';

// @dev AragonTokenSaleMock mocks current block number

contract SNTPlaceHolderMock is SNTPlaceHolder {

    uint mock_time;

    function SNTPlaceHolderMock(address _owner, address _snt, address _contribution, address _sgtExchanger)
            SNTPlaceHolder(_owner, _snt, _contribution, _sgtExchanger) {
        mock_time = now;
    }

    function getTime() internal returns (uint) {
        return mock_time;
    }

    function setMockedTime(uint _t) {
        mock_time = _t;
    }
}
