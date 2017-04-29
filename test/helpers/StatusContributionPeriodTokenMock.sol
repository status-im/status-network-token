pragma solidity ^0.4.8;

import './StatusContributionPeriodMock.sol';

// @dev StatusContributionPeriodTokenMock for ERC20 tests purpose.
// As it also deploys MiniMeTokenFactory, nonce will increase and therefore will be broken for future deployments

contract StatusContributionPeriodTokenMock is StatusContributionPeriodMock {
  function StatusContributionPeriodTokenMock(address initialAccount, uint initialBalance)
    StatusContributionPeriodMock(10, 20, msg.sender, msg.sender, 100, 50, 2)
    {
      SNT token = new SNT(new MiniMeTokenFactory());
      SNPlaceholder networkPlaceholder = new SNPlaceholder(this, token);
      token.changeController(address(this));

      setSNT(token, networkPlaceholder, new OfferingWallet(msg.sender, 20));
      allocatePreofferingTokens(initialAccount, initialBalance, uint64(now), uint64(now));
      activateOffering();
      setMockedBlockNumber(21);
      finalizeOffering(mock_hiddenCap, mock_capSecret);

      token.changeVestingWhitelister(msg.sender);
  }
}
