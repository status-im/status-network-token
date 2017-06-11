pragma solidity ^0.4.11;

/*
    Copyright 2017, Jordi Baylina

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/// @title DevTokensHolder Contract
/// @author Jordi Baylina
/// @dev This contract will hold the tokens of the developers.
///  Tokens will not be able to be collected until 6 months after the contribution
///  period ends. And it will be increasing linearly until 2 years.


//  collectable tokens
//   |                         _/--------   vestedTokens rect
//   |                       _/
//   |                     _/
//   |                   _/
//   |                 _/
//   |               _/
//   |             _/
//   |           _/
//   |          |
//   |        . |
//   |      .   |
//   |    .     |
//   +===+======+--------------+----------> time
//     Contrib   6 Months       24 Months
//       End


import "./MiniMeToken.sol";
import "./StatusContribution.sol";
import "./SafeMath.sol";


contract DevTokensHolder is Owned, SafeMath {

    uint collectedTokens;
    StatusContribution contribution;
    MiniMeToken snt;

    function DevTokensHolder(address _owner, address _contribution, address _snt) {
        owner = _owner;
        contribution = StatusContribution(_contribution);
        snt = MiniMeToken(_snt);
    }


    /// @notice The Dev (Owner) will call this method to extract the tokens
    function collectTokens() public onlyOwner {
        uint balance = snt.balanceOf(address(this));
        uint total = safeAdd(collectedTokens, snt.balanceOf(address(this)));

        uint finalized = contribution.finalized();

        if (finalized == 0) throw;
        if (safeSub(getTime(), finalized) <= months(6)) throw;

        uint canExtract = safeMul(total, safeDiv(safeSub(getTime(), finalized), months(24)));

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

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyOwner {
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
