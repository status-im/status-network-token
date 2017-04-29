pragma solidity ^0.4.8;

import "truffle/Assert.sol";
import "zeppelin/token/ERC20.sol";
import "./helpers/StatusContributionPeriodMock.sol";
import "./helpers/ThrowProxy.sol";
import "./helpers/MultisigMock.sol";
import "./helpers/NetworkMock.sol";

contract TestContributionPeriod {
  uint public initialBalance = 200 finney;

  address factory;

  ThrowProxy throwProxy;

  function beforeAll() {
    factory = address(new MiniMeTokenFactory());
  }

  function beforeEach() {
    throwProxy = new ThrowProxy(address(this));
  }

  function testHasCorrectPriceForStages() {
    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 20, address(this), address(this), 3, 1, 2);
    Assert.equal(offering.getPrice(10), 3, "Should have correct price for start stage 1");
    Assert.equal(offering.getPrice(13), 3, "Should have correct price for middle stage 1");
    Assert.equal(offering.getPrice(14), 3, "Should have correct price for final stage 1");
    Assert.equal(offering.getPrice(15), 1, "Should have correct price for start stage 2");
    Assert.equal(offering.getPrice(18), 1, "Should have correct price for middle stage 2");
    Assert.equal(offering.getPrice(19), 1, "Should have correct price for final stage 2");

    Assert.equal(offering.getPrice(9), 0, "Should have incorrect price out of offering");
    Assert.equal(offering.getPrice(20), 0, "Should have incorrect price out of offering");
  }

  function testHasCorrectPriceForMultistage() {
    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 40, address(this), address(this), 5, 1, 3);
    Assert.equal(offering.getPrice(10), 5, "Should have correct price");
    Assert.equal(offering.getPrice(19), 5, "Should have correct price");
    Assert.equal(offering.getPrice(20), 3, "Should have correct price");
    Assert.equal(offering.getPrice(25), 3, "Should have correct price");
    Assert.equal(offering.getPrice(30), 1, "Should have correct price");
    Assert.equal(offering.getPrice(39), 1, "Should have correct price");

    Assert.equal(offering.getPrice(9), 0, "Should have incorrect price out of offering");
    Assert.equal(offering.getPrice(41), 0, "Should have incorrect price out of offering");
  }

  function testAllocatesTokensInOffering() {
    MultisigMock ms = new MultisigMock();

    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 20, address(ms), address(ms), 3, 1, 2);
    ms.deployAndSetSNT(offering);
    ms.activateOffering(offering);

    offering.setMockedBlockNumber(12);
    Assert.isTrue(offering.proxyPayment.value(25 finney)(address(this)), 'proxy payment should succeed'); // Gets 5 @ 10 finney
    Assert.equal(offering.totalCollected(), 25 finney, 'Should have correct total collected');

    offering.setMockedBlockNumber(17);
    if (!offering.proxyPayment.value(10 finney)(address(this))) throw; // Gets 1 @ 20 finney

    Assert.equal(ERC20(offering.token()).balanceOf(address(this)), 85 finney, 'Should have correct balance after allocation');
    Assert.equal(ERC20(offering.token()).totalSupply(), 85 finney, 'Should have correct supply after allocation');
    Assert.equal(offering.offeringWallet().balance, 35 finney, 'Should have sent money to multisig');
    Assert.equal(offering.totalCollected(), 35 finney, 'Should have correct total collected');
  }

  function testCannotGetTokensInNotInitiatedOffering() {
    TestContributionPeriod(throwProxy).throwsWhenGettingTokensInNotInitiatedOffering();
    throwProxy.assertThrows("Should have thrown when offering is not activated");
  }

  function throwsWhenGettingTokensInNotInitiatedOffering() {
    MultisigMock ms = new MultisigMock();

    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 20, address(ms), address(this), 3, 1, 2);
    ms.deployAndSetSNT(offering);
    ms.activateOffering(offering);
    // Would need activation from this too

    offering.setMockedBlockNumber(12);
    offering.proxyPayment.value(50 finney)(address(this));
  }

  function testEmergencyStop() {
    MultisigMock ms = new MultisigMock();
    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 20, address(ms), address(ms), 3, 1, 2);
    ms.deployAndSetSNT(offering);
    ms.activateOffering(offering);

    offering.setMockedBlockNumber(12);
    Assert.isTrue(offering.proxyPayment.value(15 finney)(address(this)), 'proxy payment should succeed');
    Assert.equal(ERC20(offering.token()).balanceOf(address(this)), 45 finney, 'Should have correct balance after allocation');

    ms.emergencyStopOffering(address(offering));
    Assert.isTrue(offering.offeringStopped(), "Offering should be stopped");

    ms.restartOffering(offering);

    offering.setMockedBlockNumber(16);
    Assert.isFalse(offering.offeringStopped(), "Offering should be restarted");
    Assert.isTrue(offering.proxyPayment.value(1 finney)(address(this)), 'proxy payment should succeed');
    Assert.equal(ERC20(offering.token()).balanceOf(address(this)), 46 finney, 'Should have correct balance after allocation');
  }

  function testCantBuyTokensInStoppedOffering() {
    TestContributionPeriod(throwProxy).throwsWhenGettingTokensWithStoppedOffering();
    throwProxy.assertThrows("Should have thrown when offering is stopped");
  }

  function throwsWhenGettingTokensWithStoppedOffering() {
    MultisigMock ms = new MultisigMock();
    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 20, address(ms), address(ms), 3, 1, 2);
    ms.deployAndSetSNT(offering);
    ms.activateOffering(offering);
    offering.setMockedBlockNumber(12);

    ms.emergencyStopOffering(address(offering));
    offering.proxyPayment.value(20 finney)(address(this));
  }

  function testCantBuyTokensInEndedOffering() {
    TestContributionPeriod(throwProxy).throwsWhenGettingTokensWithEndedOffering();
    throwProxy.assertThrows("Should have thrown when offering is ended");
  }

  function throwsWhenGettingTokensWithEndedOffering() {
    MultisigMock ms = new MultisigMock();
    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 20, address(ms), address(ms), 3, 1, 2);
    ms.deployAndSetSNT(offering);
    ms.activateOffering(offering);
    offering.setMockedBlockNumber(21);

    offering.proxyPayment.value(20 finney)(address(this));
  }

  function testTokensAreLockedDuringOffering() {
    TestContributionPeriod(throwProxy).throwsWhenTransferingDuringOffering();
    throwProxy.assertThrows("Should have thrown transferring during offering");
  }

  function throwsWhenTransferingDuringOffering() {
    MultisigMock ms = new MultisigMock();
    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 20, address(ms), address(ms), 3, 1, 2);
    ms.deployAndSetSNT(offering);
    ms.activateOffering(offering);
    offering.setMockedBlockNumber(12);
    offering.proxyPayment.value(15 finney)(address(this));

    ERC20(offering.token()).transfer(0x1, 10 finney);
  }

  function testTokensAreTransferrableAfterOffering() {
    MultisigMock ms = new MultisigMock();
    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 20, address(ms), address(ms), 3, 1, 2);
    ms.deployAndSetSNT(offering);
    ms.activateOffering(offering);

    Assert.equal(SNT(offering.token()).controller(), address(offering), "Offering is controller during offering");

    offering.setMockedBlockNumber(12);
    offering.proxyPayment.value(15 finney)(address(this));
    offering.setMockedBlockNumber(22);
    ms.finalizeOffering(offering);

    Assert.equal(SNT(offering.token()).controller(), offering.networkPlaceholder(), "Network placeholder is controller after offering");

    ERC20(offering.token()).transfer(0x1, 10 finney);
    Assert.equal(ERC20(offering.token()).balanceOf(0x1), 10 finney, 'Should have correct balance after receiving tokens');
  }

  function testNetworkDeployment() {
    MultisigMock devMultisig = new MultisigMock();
    MultisigMock communityMultisig = new MultisigMock();

    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 20, address(devMultisig), address(communityMultisig), 3, 1, 2);
    devMultisig.deployAndSetSNT(offering);
    devMultisig.activateOffering(offering);
    communityMultisig.activateOffering(offering);

    Assert.equal(SNT(offering.token()).controller(), address(offering), "Offering is controller during offering");
    offering.setMockedBlockNumber(12);
    offering.proxyPayment.value(15 finney)(address(this));
    offering.setMockedBlockNumber(22);
    devMultisig.finalizeOffering(offering);

    Assert.equal(SNT(offering.token()).controller(), offering.networkPlaceholder(), "Network placeholder is controller after offering");

    doTransfer(offering.token());

    communityMultisig.deployNetwork(offering, new NetworkMock());

    TestContributionPeriod(throwProxy).doTransfer(offering.token());
    throwProxy.assertThrows("Should have thrown transferring with network mock");
  }

  function doTransfer(address token) {
    ERC20(token).transfer(0x1, 10 finney);
  }
}
