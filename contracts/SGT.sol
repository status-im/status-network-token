pragma solidity ^0.4.8;

import "./MiniMeToken.sol";

/*
    Copyright 2017, Jarrad Hope (Status Research & Development GmbH)

    // TODO Issuance & Deploy
*/

contract SGT is MiniMeToken {
  function SGT(
    address _tokenFactory
  ) MiniMeToken(
    _tokenFactory,
    0x0,                    // no parent token
    0,                      // no snapshot block number from parent
    "Status Genesis Token", // Token name
    18,                     // Decimals
    "SGT",                  // Symbol
    true                    // Enable transfers
    ) {}
}
