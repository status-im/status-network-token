pragma solidity ^0.4.6;

import "./MiniMeToken.sol";
import "./StatusContribution.sol";
import "./SafeMath.sol";

contract DevTokensHolder is Owned, SafeMath {

    uint collectedTokens;
    StatusContribution contribution;
    MiniMeToken snt;

    function DevTokensHolder( address _owner, address _contribution, address _snt) {
        owner = _owner;
        contribution = StatusContribution(_contribution);
        snt = MiniMeToken(_snt);
    }

    function collectTokens() onlyOwner {
        uint balance = snt.balanceOf(address(this));
        uint total = safeAdd(collectedTokens, snt.balanceOf(address(this)));

        uint finalized = contribution.finalized();

        if (finalized == 0) throw;
        if (safeSub(getTime(), finalized) <= months(6)) throw;

        uint canExtract = safeMul(
                                total,
                                safeDiv(
                                    safeSub( getTime(), finalized),
                                    months(24)));

        canExtract = safeSub(canExtract, collectedTokens);

        if (canExtract > balance) {
            canExtract = balance;
        }

        collectedTokens = safeAdd(collectedTokens, canExtract);
        if (!snt.transfer(owner, canExtract)) throw;

        TokensWithdrawn(owner, canExtract);
    }

    function months(uint m) internal returns(uint) {
        return safeMul(m, 30 days);
    }

    function getTime() internal returns(uint) {
        return now;
    }


//////////
// Safety Methods
//////////

    /// @notice This method can be used by the controller to extract mistakelly
    ///  sended tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) onlyOwner {
      if (_token == address(snt)) throw;
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
    event TokensWithdrawn(address indexed holder, uint amount);

}
