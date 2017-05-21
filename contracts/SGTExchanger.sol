pragma solidity ^0.4.11;

import "./MiniMeToken.sol";
import "./SafeMath.sol";

// The controllerShip of SGT should be transfered to this contract before the
// sal starts.

contract SGTExchanger is TokenController, SafeMath {

    uint totalCollected;
    MiniMeToken sgt;
    MiniMeToken snt;

    bool allowTransfers;

    function SGTExchanger(address _sgt, address _snt) {
        sgt = MiniMeToken(_sgt);
        snt = MiniMeToken(_snt);
    }

    function collect() {
        uint total = safeAdd(totalCollected, snt.balanceOf(address(this)));

        uint balance = sgt.balanceOf(msg.sender);

        totalCollected = safeAdd(totalCollected, balance);

        allowTransfers = true;
        if (!sgt.transferFrom(msg.sender, address(this), balance)) throw;
        allowTransfers = false;

        uint amount = safeDiv(
                        safeMul(total , balance),
                        sgt.totalSupply());

        if (!snt.transfer(msg.sender, amount)) throw;
    }

    function proxyPayment(address) payable returns(bool) {
        throw;
    }

    function onTransfer(address , address , uint ) returns(bool) {
        return allowTransfers;
    }

    function onApprove(address , address , uint ) returns(bool) {
        return false;
    }
}
