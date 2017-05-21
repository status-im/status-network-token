pragma solidity ^0.4.11;

import "./MiniMeToken.sol";
import "./SafeMath.sol";
import "./Owned.sol";

// The controllerShip of SGT should be transfered to this contract before the
// sal starts.

contract SGTExchanger is TokenController, SafeMath, Owned {

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

        TokensCollected(msg.sender, amount);
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

//////////
// Safety Method
//////////

    /// @notice This method can be used by the controller to extract mistakelly
    ///  sended tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) onlyOwner {
      if (_token == 0x0) {
          owner.transfer(this.balance);
          return;
      }

      MiniMeToken token = MiniMeToken(_token);
      uint balance = token.balanceOf(this);
      token.transfer(owner, balance);
      ClaimedTokens(_token, owner, balance);
    }

    event ClaimedTokens(address indexed token, address indexed controller, uint amount);
    event TokensCollected(address indexed holder, uint amount);
}
