pragma solidity ^0.4.8;

// @dev Contract to hold sale raised funds during the sale period.
// Prevents attack in which the Aragon Multisig sends raised ether
// to the sale contract to mint tokens to itself, and getting the
// funds back immediately.

contract SaleWallet {
  // Public variables
  address public multisig;
  uint public finalBlock;

  // @dev Constructor initializes public variables
  // @param _multisig The address of the multisig that will receive the funds
  // @param _finalBlock Block after which the multisig can request the funds
  function SaleWallet(address _multisig, uint _finalBlock) {
    multisig = _multisig;
    finalBlock = _finalBlock;
  }

  // @dev Receive all sent funds without any further logic
  function () payable {}

  // @dev Withdraw function sends all the funds to the wallet if conditions are correct
  function withdraw() {
    if (msg.sender != multisig) throw;        // Only the multisig can request it
    if (block.number < finalBlock) throw;     // Only on or after the final block
    suicide(multisig);                        // Suicide the contract sending all funds to multisig
  }
}
