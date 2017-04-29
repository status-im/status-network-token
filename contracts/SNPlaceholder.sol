pragma solidity ^0.4.8;

import "./interface/Controller.sol";
import "./SNT.sol";

/*
    Copyright 2017, Jorge Izquierdo (Aragon Foundation)
*/
/*

@notice The SNPlaceholder contract will take control over the SNT after the offering
        is finalized and before the Status Network is deployed.

        The contract allows for SNT transfers and transferFrom and implements the
        logic for transfering control of the token to the network when the offering
        asks it to do so.
*/

contract SNPlaceholder is Controller {
  address public offering;
  SNT public token;

  function SNPlaceholder(address _offering, address _ant) {
    offering = _offering;
    token = SNT(_ant);
  }

  function changeController(address network) {
    if (msg.sender != offering) throw;
    token.changeController(network);
    suicide(network);
  }

  // In between the offering and the network. Default settings for allowing token transfers.
  function proxyPayment(address _owner) payable returns (bool) {
    return false;
  }

  function onTransfer(address _from, address _to, uint _amount) returns (bool) {
    return true;
  }

  function onApprove(address _owner, address _spender, uint _amount) returns (bool) {
    return true;
  }
}
