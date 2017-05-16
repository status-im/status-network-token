pragma solidity ^0.4.8;

import "./MiniMeToken.sol";
import "./Controller.sol";


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

contract ICO {
  function finalized() returns (uint);
}

contract SNTPlaceHolder is Controller {
  address public owner;
  MiniMeToken public token;
  ICO public ico;
  uint public activationTime;

  function SNPlaceholder(address _owner, address _snt, address _ico) {
    owner = _owner;
    token = MiniMeToken(_snt);
    ico = ICO(_ico);
  }

  function changeController(address _newController) {
    if (msg.sender != owner) throw;
    token.changeController(_newController);
    suicide(owner);
  }

  // In between the offering and the network. Default settings for allowing token transfers.
  function proxyPayment(address ) payable returns (bool) {
    return false;
  }

  function onTransfer(address , address , uint ) returns (bool) {
    return transferable();
  }

  function onApprove(address , address , uint ) returns (bool) {
    return transferable();
  }

  function transferable() internal returns (bool) {
    if (activationTime == 0) {
      uint f = ico.finalized();
      if (f>0) {
        activationTime = f + 2 weeks;
        return (now > activationTime);
      } else {
        return false;
      }
    } else {
      return (now > activationTime);
    }
  }
}
