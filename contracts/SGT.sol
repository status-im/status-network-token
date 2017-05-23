pragma solidity ^0.4.11;

import "./MiniMeToken.sol";

/*
    Copyright 2017, Jarrad Hope (Status Research & Development GmbH)

    // TODO Issuance & Deploy
*/

contract SGT is MiniMeToken {
  uint constant D160 = 0x0010000000000000000000000000000000000000000;

  function SGT(
    address _tokenFactory
  ) MiniMeToken(
    _tokenFactory,
    0x0,                    // no parent token
    0,                      // no snapshot block number from parent
    "Status Genesis Token", // Token name
    1,                     // Decimals
    "SGT",                  // Symbol
    false                    // Enable transfers
    ) {}

    // data is an array of uints. Each uint represents a transfer.
    // The 160 LSB is the destination of the addess that wants to be sent
    // The 96 MSB is the amount of tokens that wants to be sent.
    function multiMint(uint[] data) onlyController {
        for (uint i = 0; i < data.length; i++ ) {
            address addr = address( data[i] & (D160-1) );
            uint amount = data[i] / D160;

            if (!generateTokens(addr, amount)) throw;
        }
    }
}
