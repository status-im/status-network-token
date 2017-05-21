pragma solidity ^0.4.6;

import "./MiniMeToken.sol";
import "./StatusContribution.sol";

contract DevTokensHolder is Owned {

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
        uint total = collectedTokens + snt.balanceOf(address(this));

        uint finalized = contribution.finalized();

        if (finalized == 0) throw;
        if (getTime() - finalized <= 6*30 days) throw;

        uint canExtract = total * ( getTime() - finalized) / (24 * 30 days);

        canExtract = canExtract - collectedTokens;

        if (canExtract > balance) {
            canExtract = balance;
        }

        collectedTokens += canExtract;
        if (!snt.transfer(owner, canExtract)) throw;
    }

    function getTime() internal returns(uint) {
        return now;
    }
}
