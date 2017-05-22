pragma solidity ^0.4.8;

import "./StatusContribution.sol";

// @dev Contract to hold sale raised funds during the sale period.
// Prevents attack in which the Aragon Multisig sends raised ether
// to the sale contract to mint tokens to itself, and getting the
// funds back immediately.

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
    if (contribution.finalized() != 0) return doWithdraw();      // Allow when sale is finalized
  }

  function doWithdraw() internal {
    if (!multisig.send(this.balance)) throw;
  }
}
