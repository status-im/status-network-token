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

/// @title ContributionWallet Contract
/// @author Jordi Baylina
/// @dev This contract will be hold the Ether during the contribution period.
///  The idea of this contract is to avoid recycling Ether during the contribution
///  period. So all the ETH collected will be locked here until the contribution
///  period ends

// @dev Contract to hold sale raised funds during the sale period.
// Prevents attack in which the Aragon Multisig sends raised ether
// to the sale contract to mint tokens to itself, and getting the
// funds back immediately.


import "./StatusContribution.sol";


contract ContributionWallet {

    // Public variables
    address public multisig;
    uint public finalBlock;
    StatusContribution public contribution;

    // @dev Constructor initializes public variables
    // @param _multisig The address of the multisig that will receive the funds
    // @param _finalBlock Block after which the multisig can request the funds
    // @param _contribution Address of the StatusContribution contract
    function ContributionWallet(address _multisig, uint _finalBlock, address _contribution) {
        multisig = _multisig;
        finalBlock = _finalBlock;
        contribution = StatusContribution(_contribution);
    }

    // @dev Receive all sent funds without any further logic
    function () public payable {}

    // @dev Withdraw function sends all the funds to the wallet if conditions are correct
    function withdraw() public {
        if (msg.sender != multisig) throw;                       // Only the multisig can request it
        if (block.number > finalBlock) return doWithdraw();      // Allow after the final block
        if (contribution.finalized() != 0) return doWithdraw();  // Allow when sale is finalized
    }

    function doWithdraw() private {
        if (!multisig.send(this.balance)) throw;
    }

}
