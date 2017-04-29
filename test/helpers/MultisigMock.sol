pragma solidity ^0.4.8;

import './StatusContributionPeriodMock.sol';

contract MultisigMock {
  function deployAndSetSNT(address offering) {
    SNT token = new SNT(new MiniMeTokenFactory());
    SNPlaceholder networkPlaceholder = new SNPlaceholder(offering, token);
    token.changeController(address(offering));

    StatusContributionPeriod s = StatusContributionPeriod(offering);
    token.setCanCreateGrants(offering, true);
    s.setSNT(token, networkPlaceholder, new OfferingWallet(s.statusDevMultisig(), s.finalBlock()));
  }

  function activateOffering(address offering) {
    StatusContributionPeriod(offering).activateOffering();
  }

  function emergencyStopOffering(address offering) {
    StatusContributionPeriod(offering).emergencyStopOffering();
  }

  function restartOffering(address offering) {
    StatusContributionPeriod(offering).restartOffering();
  }

  function finalizeOffering(address offering) {
    finalizeOffering(offering, StatusContributionPeriodMock(offering).mock_hiddenCap());
  }

  function finalizeOffering(address offering, uint256 cap) {
    StatusContributionPeriod(offering).finalizeOffering(cap, StatusContributionPeriodMock(offering).mock_capSecret());
  }

  function deployNetwork(address offering, address network) {
    StatusContributionPeriod(offering).deployNetwork(network);
  }

  function () payable {}
}
