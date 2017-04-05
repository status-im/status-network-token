pragma solidity ^0.4.8;

import "./MiniMeToken.sol";
import "./IrrevocableVestedToken.sol";

// @notice ANT is a composed contract of MiniMeToken and IrrevocableVestedToken

// The first base class is IrrevocableVestedToken, it will intercept all transfer
// and transferFrom function calls, perform the check of whether that holder can
// transfer that amount of tokens and it is correct, it will call super.transfer*,
// where MiniMeToken logic be executed.

// Both MiniMeToken and IrrevocableVestedToken conform to the ERC20 interface,
// but it is MiniMeToken the one that actually implements it.

// For simplicity, token grants are not saved in MiniMe type checkpoints.
// Vanilla cloning ANT will clone it into a MiniMeToken without vesting.
// More complex cloning could account for past vesting calendars.

contract ANT is MiniMeToken, IrrevocableVestedToken {
  // @dev ANT constructor just parametrizes the MiniMeToken constructor
  function ANT(
    address _tokenFactory
  ) MiniMeToken(
    _tokenFactory,
    0x0,          // no parent token
    0,            // no snapshot block number from parent
    "Token name", // Token name // TODO: Token name = 'Aragon Network Token'
    18,           // Decimals
    "ANT",        // Symbol
    true          // Enable transfers
    ) {}
}
