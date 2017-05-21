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
    }

    function months(uint m) internal returns(uint) {
        return safeMul(m, 30 days);
    }

    function getTime() internal returns(uint) {
        return now;
    }
}
