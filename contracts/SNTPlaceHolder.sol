pragma solidity ^0.4.8;

import "./MiniMeToken.sol";
import "./StatusContribution.sol";


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

contract SNTPlaceHolder is TokenController {
  address public owner;
  MiniMeToken public snt;
  StatusContribution public contribution;
  uint public activationTime;

  function SNPlaceholder(address _owner, address _snt, address _contribution) {
    owner = _owner;
    snt = MiniMeToken(_snt);
    contribution = StatusContribution(_contribution);
  }

  function changeController(address _newController) {
    if (msg.sender != owner) throw;
    snt.changeController(_newController);
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
      uint f = contribution.finalized();
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
