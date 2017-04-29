pragma solidity ^0.4.8;

import "truffle/Assert.sol";
import "zeppelin/token/ERC20.sol";
import "./helpers/StatusContributionPeriodMock.sol";
import "./helpers/ThrowProxy.sol";
import "./helpers/MultisigMock.sol";

contract TestTokenPreoffering {
  uint public initialBalance = 200 finney;

  SNT token;

  ThrowProxy throwProxy;

  function beforeEach() {
    throwProxy = new ThrowProxy(address(this));
  }

  function deployAndSetSNT(StatusContributionPeriod offering) {
    SNT a = new SNT(new MiniMeTokenFactory());
    a.changeController(offering);
    a.setCanCreateGrants(offering, true);
    offering.setSNT(a, new SNPlaceholder(address(offering), a), new OfferingWallet(offering.statusDevMultisig(), offering.finalBlock()));
  }

  function testCreateOffering() {
    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 20, 0x1, 0x2, 3, 1, 2);

    Assert.isFalse(offering.isActivated(), "Offering should be activated");
    Assert.equal(offering.totalCollected(), 0, "Should start with 0 funds collected");
  }

  function testCantInitiateIncorrectOffering() {
    TestTokenPreoffering(throwProxy).throwIfStartPastBlocktime();
    throwProxy.assertThrows("Should throw when starting a offering in a past block");
  }

  function throwIfStartPastBlocktime() {
    new StatusContributionPeriodMock(0, 20, 0x1, 0x2, 3, 1, 2);
  }

  function testActivateOffering() {
    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 20, address(this), address(this), 3, 1, 2);
    deployAndSetSNT(offering);
    offering.activateOffering();
    Assert.isTrue(offering.isActivated(), "Should be activated");
  }

  function testCannotActivateBeforeDeployingSNT() {
    TestTokenPreoffering(throwProxy).throwsWhenActivatingBeforeDeployingSNT();
    throwProxy.assertThrows("Should have thrown when activating before deploying SNT");
  }

  function throwsWhenActivatingBeforeDeployingSNT() {
    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 20, address(this), address(this), 3, 1, 2);
    offering.activateOffering();
  }

  function testCannotRedeploySNT() {
    TestTokenPreoffering(throwProxy).throwsWhenRedeployingSNT();
    throwProxy.assertThrows("Should have thrown when redeploying SNT");
  }

  function throwsWhenRedeployingSNT() {
    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 20, address(this), address(this), 3, 1, 2);
    deployAndSetSNT(offering);
    deployAndSetSNT(offering);
  }

  function testOnlyMultisigCanDeploySNT() {
    TestTokenPreoffering(throwProxy).throwsWhenNonMultisigDeploysSNT();
    throwProxy.assertThrows("Should have thrown when deploying SNT from not multisig");
  }

  function throwsWhenNonMultisigDeploysSNT() {
    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 20, 0x1, 0x3, 3, 1, 2);
    deployAndSetSNT(offering);
  }

  function testThrowsIfPlaceholderIsBad() {
    TestTokenPreoffering(throwProxy).throwsWhenNetworkPlaceholderIsBad();
    throwProxy.assertThrows("Should have thrown when placeholder is not correct");
  }

  function throwsWhenNetworkPlaceholderIsBad() {
    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 20, address(this), address(this), 3, 1, 2);
    SNT a = new SNT(new MiniMeTokenFactory());
    a.changeController(offering);
    offering.setSNT(a, new SNPlaceholder(address(offering), address(offering)), new OfferingWallet(offering.statusDevMultisig(), offering.finalBlock())); // should be initialized with token address
  }

  function testThrowsIfOfferingIsNotTokenController() {
    TestTokenPreoffering(throwProxy).throwsWhenOfferingIsNotTokenController();
    throwProxy.assertThrows("Should have thrown when offering is not token controller");
  }

  function throwsWhenOfferingIsNotTokenController() {
    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 20, address(this), address(this), 3, 1, 2);
    SNT a = new SNT(new MiniMeTokenFactory());
    // Not called a.changeController(offering);
    offering.setSNT(a, new SNPlaceholder(address(offering), a), new OfferingWallet(offering.statusDevMultisig(), offering.finalBlock())); // should be initialized with token address
  }

  function testThrowsOfferingWalletIncorrectBlock() {
    TestTokenPreoffering(throwProxy).throwsOfferingWalletIncorrectBlock();
    throwProxy.assertThrows("Should have thrown offering wallet releases in incorrect block");
  }

  function throwsOfferingWalletIncorrectBlock() {
    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 20, address(this), address(this), 3, 1, 2);
    SNT a = new SNT(new MiniMeTokenFactory());
    a.changeController(offering);
    offering.setSNT(a, new SNPlaceholder(address(offering), a), new OfferingWallet(offering.statusDevMultisig(), offering.finalBlock() - 1));
  }

  function testThrowsOfferingWalletIncorrectMultisig() {
    TestTokenPreoffering(throwProxy).throwsOfferingWalletIncorrectMultisig();
    throwProxy.assertThrows("Should have thrown when offering wallet has incorrect multisig");
  }

  function throwsOfferingWalletIncorrectMultisig() {
    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 20, address(this), address(this), 3, 1, 2);
    SNT a = new SNT(new MiniMeTokenFactory());
    a.changeController(offering);
    offering.setSNT(a, new SNPlaceholder(address(offering), a), new OfferingWallet(0x1a77ed, offering.finalBlock()));
  }

  function testSetPreofferingTokens() {
    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 20, address(this), 0x2, 3, 1, 2);
    deployAndSetSNT(offering);
    offering.allocatePreofferingTokens(0x1, 100 finney, uint64(now + 12 weeks), uint64(now + 24 weeks));
    offering.allocatePreofferingTokens(0x2, 30 finney, uint64(now + 12 weeks), uint64(now + 24 weeks));
    offering.allocatePreofferingTokens(address(this), 20 finney, uint64(now + 12 weeks), uint64(now + 24 weeks));
    Assert.equal(ERC20(offering.token()).balanceOf(0x1), 100 finney, 'Should have correct balance after allocation');
    Assert.equal(MiniMeIrrevocableVestedToken(offering.token()).transferableTokens(0x1, uint64(now)), 0, 'Should have 0 tokens transferable now');
    Assert.equal(MiniMeIrrevocableVestedToken(offering.token()).transferableTokens(0x1, uint64(now + 12 weeks - 1)), 0, 'Should have 0 tokens transferable just before cliff');
    Assert.equal(MiniMeIrrevocableVestedToken(offering.token()).transferableTokens(0x1, uint64(now + 12 weeks)), 50 finney, 'Should have some tokens transferable after cliff');
    Assert.equal(MiniMeIrrevocableVestedToken(offering.token()).transferableTokens(0x1, uint64(now + 18 weeks)), 75 finney, 'Should have some tokens transferable during vesting');
    Assert.equal(MiniMeIrrevocableVestedToken(offering.token()).transferableTokens(0x1, uint64(now + 21 weeks)), 87500 szabo, 'Should have some tokens transferable during vesting');
    Assert.equal(MiniMeIrrevocableVestedToken(offering.token()).transferableTokens(0x1, uint64(now + 24 weeks)), 100 finney, 'Should have all tokens transferable after vesting');
    Assert.equal(ERC20(offering.token()).totalSupply(), 150 finney, 'Should have correct supply after allocation');

    Assert.equal(ERC20(offering.token()).balanceOf(this), 20 finney, 'Should have correct balance');
    TestTokenPreoffering(throwProxy).throwsWhenTransferingPreofferingTokensBeforeCliff(offering.token());
    throwProxy.assertThrows("Should have thrown when transfering preoffering tokens");
  }

  function throwsWhenTransferingPreofferingTokensBeforeCliff(address token) {
    ERC20(token).transfer(0xdead, 1);
  }

  function testCannotSetPreofferingTokensAfterActivation() {
    TestTokenPreoffering(throwProxy).throwIfSetPreofferingTokensAfterActivation();
    throwProxy.assertThrows("Should have thrown when setting tokens after activation");
  }

  function throwIfSetPreofferingTokensAfterActivation() {
    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 20, address(this), address(this), 3, 1, 2);
    deployAndSetSNT(offering);
    offering.activateOffering(); // this is both multisigs
    offering.allocatePreofferingTokens(0x1, 100, uint64(now + 12 weeks), uint64(now + 24 weeks));
  }

  function testCannotSetPreofferingTokensAfterOfferingStarts() {
    TestTokenPreoffering(throwProxy).throwIfSetPreofferingTokensAfterOfferingStarts();
    throwProxy.assertThrows("Should have thrown when setting tokens after offering started");
  }

  function throwIfSetPreofferingTokensAfterOfferingStarts() {
    StatusContributionPeriodMock offering = new StatusContributionPeriodMock(10, 20, address(this), address(this), 3, 1, 2);
    deployAndSetSNT(offering);
    offering.setMockedBlockNumber(13);
    offering.allocatePreofferingTokens(0x1, 100, uint64(now + 12 weeks), uint64(now + 24 weeks));
  }
}
