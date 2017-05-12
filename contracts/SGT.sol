pragma solidity ^0.4.8;

import "./MiniMeToken.sol";

/*
    Copyright 2017, Jarrad Hope (Status Research & Development GmbH)

    // TODO Issuance & Deploy
*/

contract SGT is MiniMeToken {
  uint constant D160 = 0x10000000000000000000000000000000000000000;

  function SGT(
    address _tokenFactory
  ) MiniMeToken(
    _tokenFactory,
    0x0,                    // no parent token
    0,                      // no snapshot block number from parent
    "Status Genesis Token", // Token name
    18,                     // Decimals
    "SGT",                  // Symbol
    false                    // Enable transfers
    ) {}

    // _transfers is an array of uints. Each uint represents a transfer.
    // The 160 LSB is the destination of the addess that wants to be sent
    // The 96 MSB is the amount of tokens that wants to be sent.
    // If _toEmpty is true, then this transfer is allowed only if the recipient
    // has no tokens. This is very important to prevent double sends in the case
    // a script needs to be restarted
    function multiTransfer(uint[] _transfers, bool _toEmpty) {
        for (uint i=0; i<_transfers.length; i++) {
            address to = address( _transfers[i] & (D160-1) );
            uint amount = _transfers[i] / D160;
            if ((!_toEmpty) || (balanceOf(to) == 0)) {
                super.transferFrom(msg.sender, to, amount);
            }
        }
    }
}
