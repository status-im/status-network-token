pragma solidity ^0.4.8;

import "truffle/Assert.sol";
import "zeppelin/token/ERC20.sol";
import "./helpers/StatusContributionPeriodMock.sol";
import "./helpers/ThrowProxy.sol";
import "./helpers/MultisigMock.sol";
import "./helpers/NetworkMock.sol";

contract TestContributionPeriodCap {
  uint public initialBalance = 250 finney;

  address factory;

  ThrowProxy throwProxy;

  function beforeAll() {
    factory = address(new MiniMeTokenFactory());
  }

  function beforeEach() {
    throwProxy = new ThrowProxy(address(this));
  }

  function testCantFinalizeNotEndedOffering() {
    TestContributionPeriodCap(throwProxy).throwsWhenFinalizingNotEndedOffering();
    throwProxy.assertThrows("Should have thrown when offering is ended");
  }

  function throwsWhenFinalizingNotEndedOffering() {
    MultisigMock ms = new MultisigMock();
    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 20, address(ms), address(ms), 3, 1, 2);
    ms.deployAndSetSNT(offering);
    ms.activateOffering(offering);
    offering.setMockedBlockNumber(19);
    ms.finalizeOffering(offering);
  }

  function testCantFinalizeIfNotMultisig() {
    TestContributionPeriodCap(throwProxy).throwsWhenFinalizingIfNotMultisig();
    throwProxy.assertThrows("Should have thrown if not multisig");
  }

  function throwsWhenFinalizingIfNotMultisig() {
    MultisigMock ms = new MultisigMock();
    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 20, address(ms), address(ms), 3, 1, 2);
    ms.deployAndSetSNT(offering);
    ms.activateOffering(offering);
    offering.setMockedBlockNumber(30);
    offering.finalizeOffering(1, 1);
  }

  function testCantFinalizeWithIncorrectCap() {
    TestContributionPeriodCap(throwProxy).throwsWhenFinalizingWithIncorrectCap();
    throwProxy.assertThrows("Should have thrown if incorrect cap");
  }

  function throwsWhenFinalizingWithIncorrectCap() {
    MultisigMock ms = new MultisigMock();
    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 20, address(ms), address(ms), 5, 1, 2);
    ms.deployAndSetSNT(offering);
    ms.activateOffering(offering);
    offering.setMockedBlockNumber(21);
    ms.finalizeOffering(offering, 101 finney); // cap is 100
  }

  function testCanFinalizeOnCap() {
    MultisigMock ms = new MultisigMock();
    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 20, address(ms), address(ms), 5, 1, 2);
    ms.deployAndSetSNT(offering);
    ms.activateOffering(offering);
    offering.setMockedBlockNumber(12);
    offering.proxyPayment.value(100 finney)(address(this));

    offering.revealCap(100 finney, offering.mock_capSecret());

    Assert.isTrue(offering.offeringFinalized(), 'Offering should be finished after revealing cap');
  }

  function testFinalizingBeforeCapChangesHardCap() {
    MultisigMock ms = new MultisigMock();
    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 20, address(ms), address(ms), 5, 1, 2);
    ms.deployAndSetSNT(offering);
    ms.activateOffering(offering);
    offering.setMockedBlockNumber(12);
    offering.proxyPayment.value(99 finney)(address(this));

    offering.revealCap(100 finney, offering.mock_capSecret());

    Assert.equal(offering.hardCap(), 100 finney, 'Revealing cap should change hard cap');
  }

  function testHardCap() {
    TestContributionPeriodCap(throwProxy).throwsWhenHittingHardCap();
    throwProxy.assertThrows("Should have thrown when hitting hard cap");
  }

  function throwsWhenHittingHardCap() {
    MultisigMock ms = new MultisigMock();
    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 20, address(ms), address(ms), 5, 1, 2);
    ms.deployAndSetSNT(offering);
    ms.activateOffering(offering);
    offering.setMockedBlockNumber(12);
    offering.setMockedTotalCollected(1499999 ether + 950 finney); // hard cap is 1.5m
    offering.proxyPayment.value(60 finney)(address(this));
  }

  function testCanFinalizeEndedOffering() {
    MultisigMock ms = new MultisigMock();
    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 20, address(ms), address(ms), 5, 1, 2);
    ms.deployAndSetSNT(offering);
    ms.activateOffering(offering);
    offering.setMockedBlockNumber(12);
    offering.proxyPayment.value(14 finney)(address(this));

    Assert.equal(ERC20(offering.token()).balanceOf(address(this)), 70 finney, 'Should have correct balance after allocation');
    Assert.equal(ERC20(offering.token()).totalSupply(), 70 finney, 'Should have correct supply before ending offering');

    offering.setMockedBlockNumber(21);
    ms.finalizeOffering(offering);

    Assert.equal(ERC20(offering.token()).balanceOf(address(ms)), 30 finney, 'Should have correct balance after ending offering');
    Assert.equal(ERC20(offering.token()).totalSupply(), 100 finney, 'Should have correct supply after ending offering');
  }
}
