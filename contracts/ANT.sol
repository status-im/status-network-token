pragma solidity ^0.4.8;

import "./MiniMeIrrevocableVestedToken.sol";

contract ANT is MiniMeIrrevocableVestedToken {
  // @dev ANT constructor just parametrizes the MiniMeToken constructor
  function ANT()
    MiniMeIrrevocableVestedToken(
      new MiniMeTokenFactory(),
      0x0,                    // no parent token
      0,                      // no snapshot block number from parent
      "Aragon Network Token", // Token name
      18,                     // Decimals
      "ANT",                  // Symbol
      true                    // Enable transfers
      ) {}
}
