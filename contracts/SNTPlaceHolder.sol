pragma solidity ^0.4.8;

import "./MiniMeToken.sol";
import "./StatusContribution.sol";


/*
    Copyright 2017, Jorge Izquierdo (Aragon Foundation)
*/
/*

@notice The SNTPlaceholder contract will take control over the SNT after the offering
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
  address public sgtExchanger;

  function SNTPlaceHolder(address _owner, address _snt, address _contribution, address _sgtExchanger) {
    owner = _owner;
    snt = MiniMeToken(_snt);
    contribution = StatusContribution(_contribution);
    sgtExchanger = _sgtExchanger;
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

  function onTransfer(address _from, address , uint ) returns (bool) {
    return transferable(_from);
  }

  function onApprove(address _from, address , uint ) returns (bool) {
    return transferable(_from);
  }

  function transferable(address _from) internal returns (bool) {
    // Allow the exchanger to work from the begining
    if (activationTime == 0) {
      uint f = contribution.finalized();
      if (f>0) {
        activationTime = f + 2 weeks;
      } else {
        return false;
      }
    }
    return (getTime() > activationTime) || (_from == sgtExchanger);
  }

  function getTime() internal returns(uint) {
    return now;
  }
}
