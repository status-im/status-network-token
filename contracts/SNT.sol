pragma solidity ^0.4.8;

import "./MiniMeIrrevocableVestedToken.sol";

/*
    Copyright 2017, Jorge Izquierdo (Aragon Foundation)

*/

contract SNT is MiniMeIrrevocableVestedToken {
  // @dev SNT constructor just parametrizes the MiniMeIrrevocableVestedToken constructor
  function SNT(
    address _tokenFactory
  ) MiniMeIrrevocableVestedToken(
    _tokenFactory,
    0x0,                    // no parent token
    0,                      // no snapshot block number from parent
    "Status Network Token", // Token name
    18,                     // Decimals
    "SNT",                  // Symbol
    true                    // Enable transfers
    ) {}
}
