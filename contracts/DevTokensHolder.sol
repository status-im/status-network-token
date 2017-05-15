pragma solidity ^0.4.6;

import "./MiniMeToken.sol";
import "./StatusICO.sol";

contract DevTokensHolder is Owned {

    uint collectedTokens;
    StatusICO ico;
    MiniMeToken snt;

    function DevTokensHolder( address _ico, address _snt) {
        ico = StatusICO(_ico);
        snt = MiniMeToken(_snt);
    }

    function collectTokens() onlyOwner {
        uint balance = snt.balanceOf(address(this));
        uint total = collectedTokens + snt.balanceOf(address(this));

        uint finalized = ico.finalized();

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
