pragma solidity ^0.4.8;

import "truffle/Assert.sol";
import "zeppelin/token/ERC20.sol";
import "./helpers/AragonTokenSaleMock.sol";
import "./helpers/ThrowProxy.sol";
import "./helpers/MultisigMock.sol";

contract TestTokenSale {
  uint public initialBalance = 200 finney;
  address factory;

  ThrowProxy throwProxy;

  function beforeAll() {
    factory = address(new MiniMeTokenFactory());
  }

  function beforeEach() {
    throwProxy = new ThrowProxy(address(this));
  }

  function testCreateSale() {
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, 0x1, 0x2, 2, 1, 2);

    Assert.isFalse(sale.isActivated(), "Sale should be activated");
    Assert.equal(sale.totalCollected(), 0, "Should start with 0 funds collected");
  }

  function testCantInitiateIncorrectSale() {
    TestTokenSale(throwProxy).throwIfStartPastBlocktime();
    throwProxy.assertThrows("Should throw when starting a sale in a past block");
  }

  function throwIfStartPastBlocktime() {
    new AragonTokenSaleMock(0, 20, 0x1, 0x2, 2, 1, 2);
  }

  function testActivateSale() {
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, address(this), address(this), 2, 1, 2);
    sale.deployANT(factory, true);
    sale.activateSale();
    Assert.isTrue(sale.isActivated(), "Should be activated");
  }

  function testCannotActivateBeforeDeployingANT() {
    TestTokenSale(throwProxy).throwsWhenActivatingBeforeDeployingANT();
    throwProxy.assertThrows("Should have thrown when activating before deploying ANT");
  }

  function throwsWhenActivatingBeforeDeployingANT() {
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, address(this), address(this), 2, 1, 2);
    sale.activateSale();
  }

  function testCannotRedeployANT() {
    TestTokenSale(throwProxy).throwsWhenRedeployingANT();
    throwProxy.assertThrows("Should have thrown when redeploying ANT");
  }

  function throwsWhenRedeployingANT() {
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, address(this), address(this), 2, 1, 2);
    sale.deployANT(factory, true);
    sale.deployANT(factory, true);
  }

  function testOnlyMultisigCanDeployANT() {
    TestTokenSale(throwProxy).throwsWhenNonMultisigDeploysANT();
    throwProxy.assertThrows("Should have thrown when deploying ANT from not multisig");
  }

  function throwsWhenNonMultisigDeploysANT() {
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, 0x1, 0x3, 2, 1, 2);
    sale.deployANT(factory, true);
  }

  function testSetPresaleTokens() {
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, address(this), 0x2, 2, 1, 2);
    sale.deployANT(factory, true);
    sale.allocatePresaleTokens(0x1, 100);
    sale.allocatePresaleTokens(0x2, 30);
    sale.allocatePresaleTokens(address(this), 20);
    Assert.equal(ERC20(sale.token()).balanceOf(0x1), 100, 'Should have correct balance after allocation');
    Assert.equal(ERC20(sale.token()).totalSupply(), 150, 'Should have correct supply after allocation');
  }

  function testCannotSetPresaleTokensAfterActivation() {
    TestTokenSale(throwProxy).throwIfSetPresaleTokensAfterActivation();
    throwProxy.assertThrows("Should have thrown when setting tokens after activation");
  }

  function throwIfSetPresaleTokensAfterActivation() {
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, address(this), address(this), 2, 1, 2);
    sale.deployANT(factory, true);
    sale.activateSale(); // this is both multisigs
    sale.allocatePresaleTokens(0x1, 100);
  }

  function testCannotSetPresaleTokensAfterSaleStarts() {
    TestTokenSale(throwProxy).throwIfSetPresaleTokensAfterSaleStarts();
    throwProxy.assertThrows("Should have thrown when setting tokens after sale started");
  }

  function throwIfSetPresaleTokensAfterSaleStarts() {
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, address(this), address(this), 2, 1, 2);
    sale.deployANT(factory, true);
    sale.setMockedBlockNumber(13);
    sale.allocatePresaleTokens(0x1, 100);
  }

  function testHasCorrectPriceForStages() {
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, address(this), address(this), 2, 1, 2);
    Assert.equal(sale.getPrice(10), 2, "Should have correct price for start stage 1");
    Assert.equal(sale.getPrice(13), 2, "Should have correct price for middle stage 1");
    Assert.equal(sale.getPrice(14), 2, "Should have correct price for final stage 1");
    Assert.equal(sale.getPrice(15), 1, "Should have correct price for start stage 2");
    Assert.equal(sale.getPrice(18), 1, "Should have correct price for middle stage 2");
    Assert.equal(sale.getPrice(19), 1, "Should have correct price for final stage 2");

    Assert.equal(sale.getPrice(9), 0, "Should have incorrect price out of sale");
    Assert.equal(sale.getPrice(20), 0, "Should have incorrect price out of sale");
  }

  function testHasCorrectPriceForMultistage() {
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 40, address(this), address(this), 3, 1, 3);
    Assert.equal(sale.getPrice(10), 3, "Should have correct price");
    Assert.equal(sale.getPrice(19), 3, "Should have correct price");
    Assert.equal(sale.getPrice(20), 2, "Should have correct price");
    Assert.equal(sale.getPrice(25), 2, "Should have correct price");
    Assert.equal(sale.getPrice(30), 1, "Should have correct price");
    Assert.equal(sale.getPrice(39), 1, "Should have correct price");

    Assert.equal(sale.getPrice(9), 0, "Should have incorrect price out of sale");
    Assert.equal(sale.getPrice(41), 0, "Should have incorrect price out of sale");
  }

  function testAllocatesTokensInSale() {
    MultisigMock ms = new MultisigMock();

    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, address(ms), address(ms), 2, 1, 2);
    ms.activateSale(sale, factory);

    sale.setMockedBlockNumber(12);
    Assert.isTrue(sale.proxyPayment.value(25 finney)(address(this)), 'proxy payment should succeed'); // Gets 5 @ 10 finney

    sale.setMockedBlockNumber(17);
    if (!sale.proxyPayment.value(10 finney)(address(this))) throw; // Gets 1 @ 20 finney

    Assert.equal(ERC20(sale.token()).balanceOf(address(this)), 60 finney, 'Should have correct balance after allocation');
    Assert.equal(ERC20(sale.token()).totalSupply(), 60 finney, 'Should have correct supply after allocation');
    Assert.equal(ms.balance, 35 finney, 'Should have sent money to multisig');
  }

  function testCannotGetTokensInNotInitiatedSale() {
    TestTokenSale(throwProxy).throwsWhenGettingTokensInNotInitiatedSale();
    throwProxy.assertThrows("Should have thrown when sale is not activated");
  }

  function throwsWhenGettingTokensInNotInitiatedSale() {
    MultisigMock ms = new MultisigMock();

    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, address(ms), address(this), 2, 1, 2);
    ms.activateSale(sale, factory);
    // Would need activation from this too

    sale.setMockedBlockNumber(12);
    sale.proxyPayment.value(50 finney)(address(this));
  }

  function testEmergencyStop() {
    MultisigMock ms = new MultisigMock();
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, address(ms), address(ms), 2, 1, 2);
    ms.activateSale(sale, factory);

    sale.setMockedBlockNumber(12);
    Assert.isTrue(sale.proxyPayment.value(15 finney)(address(this)), 'proxy payment should succeed');
    Assert.equal(ERC20(sale.token()).balanceOf(address(this)), 30 finney, 'Should have correct balance after allocation');

    ms.emergencyStopSale(address(sale));
    Assert.isTrue(sale.saleStopped(), "Sale should be stopped");

    ms.restartSale(sale);

    sale.setMockedBlockNumber(16);
    Assert.isFalse(sale.saleStopped(), "Sale should be restarted");
    Assert.isTrue(sale.proxyPayment.value(1 finney)(address(this)), 'proxy payment should succeed');
    Assert.equal(ERC20(sale.token()).balanceOf(address(this)), 31 finney, 'Should have correct balance after allocation');
  }

  function testCantBuyTokensInStoppedSale() {
    TestTokenSale(throwProxy).throwsWhenGettingTokensWithStoppedSale();
    throwProxy.assertThrows("Should have thrown when sale is stopped");
  }

  function throwsWhenGettingTokensWithStoppedSale() {
    MultisigMock ms = new MultisigMock();
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, address(ms), address(ms), 2, 1, 2);
    ms.activateSale(sale, factory);
    sale.setMockedBlockNumber(12);

    ms.emergencyStopSale(address(sale));
    sale.proxyPayment.value(20 finney)(address(this));
  }

  function testCantBuyTokensInEndedSale() {
    TestTokenSale(throwProxy).throwsWhenGettingTokensWithEndedSale();
    throwProxy.assertThrows("Should have thrown when sale is ended");
  }

  function throwsWhenGettingTokensWithEndedSale() {
    MultisigMock ms = new MultisigMock();
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, address(ms), address(ms), 2, 1, 2);
    ms.activateSale(sale, factory);
    sale.setMockedBlockNumber(21);

    sale.proxyPayment.value(20 finney)(address(this));
  }

  function testCantFinalizeNotEndedSale() {
    TestTokenSale(throwProxy).throwsWhenFinalizingNotEndedSale();
    throwProxy.assertThrows("Should have thrown when sale is ended");
  }

  function throwsWhenFinalizingNotEndedSale() {
    MultisigMock ms = new MultisigMock();
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, address(ms), address(ms), 2, 1, 2);
    ms.activateSale(sale, factory);
    sale.setMockedBlockNumber(19);
    ms.finalizeSale(sale);
  }

  function testCantFinalizeIfNotMultisig() {
    TestTokenSale(throwProxy).throwsWhenFinalizingIfNotMultisig();
    throwProxy.assertThrows("Should have thrown if not multisig");
  }

  function throwsWhenFinalizingIfNotMultisig() {
    MultisigMock ms = new MultisigMock();
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, address(ms), address(ms), 2, 1, 2);
    ms.activateSale(sale, factory);
    sale.setMockedBlockNumber(30);
    sale.finalizeSale();
  }

  function testCanFinalizeEndedSale() {
    MultisigMock ms = new MultisigMock();
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, address(ms), address(ms), 2, 1, 2);
    ms.activateSale(sale, factory);
    sale.setMockedBlockNumber(12);
    sale.proxyPayment.value(15 finney)(address(this));

    Assert.equal(ERC20(sale.token()).balanceOf(address(this)), 30 finney, 'Should have correct balance after allocation');
    Assert.equal(ERC20(sale.token()).totalSupply(), 30 finney, 'Should have correct supply before ending sale');

    sale.setMockedBlockNumber(21);
    ms.finalizeSale(sale);

    Assert.equal(ERC20(sale.token()).balanceOf(address(ms)), 10 finney, 'Should have correct balance after ending sale');
    Assert.equal(ERC20(sale.token()).totalSupply(), 40 finney, 'Should have correct supply after ending sale');
  }
}
