pragma solidity ^0.4.6;

import "./MiniMeToken.sol";
import "./StatusContribution.sol";

contract DevTokensHolder is Owned {

    uint collectedTokens;
    StatusContribution contribution;
    MiniMeToken snt;

    function DevTokensHolder( address _contribution, address _snt) {
        contribution = StatusContribution(_contribution);
        snt = MiniMeToken(_snt);
    }

    function collectTokens() onlyOwner {
        uint balance = snt.balanceOf(address(this));
        uint total = collectedTokens + snt.balanceOf(address(this));

        uint finalized = contribution.finalized();

        if (finalized == 0) throw;
        if (now - finalized <= 6*30 days) return;

        uint canExtract = total * ( now - (finalized + 6 * 30 days)) / (18 * 30 days);

        canExtract = canExtract - collectedTokens;

        if (canExtract > balance) {
            canExtract = balance;
        }

        collectedTokens += canExtract;
        if (!snt.transfer(owner, canExtract)) throw;
    }
}
