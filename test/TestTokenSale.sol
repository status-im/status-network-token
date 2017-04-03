pragma solidity ^0.4.8;

import "truffle/Assert.sol";
import "zeppelin/token/ERC20.sol";
import "./helpers/AragonTokenSaleMock.sol";
import "./helpers/ThrowProxy.sol";

contract TestTokenSale {
  uint public initialBalance = 0 ether;
  address factory;

  ThrowProxy throwProxy;

  function beforeAll() {
    factory = address(new MiniMeTokenFactory());
  }

  function beforeEach() {
    throwProxy = new ThrowProxy(address(this));
  }

  function testCreateSale() {
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, 0x1, 0x2, 10 finney, 13 finney, 2);

    Assert.isFalse(sale.isActivated(), "Sale should be activated");
    Assert.equal(sale.totalCollected(), 0, "Should start with 0 funds collected");
  }

  function testCantInitiateIncorrectSale() {
    TestTokenSale(throwProxy).throwIfStartPastBlocktime();
    throwProxy.assertThrows("Should throw when starting a sale in a past block");
  }

  function throwIfStartPastBlocktime() {
    new AragonTokenSaleMock(0, 20, 0x1, 0x2, 10 finney, 13 finney, 2);
  }

  function testActivateSale() {
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, address(this), address(this), 10 finney, 13 finney, 2);
    sale.deployANT(factory, true);
    sale.activateSale();
    Assert.isTrue(sale.isActivated(), "Should be activated");
  }

  function testCannotActivateBeforeDeployingANT() {
    TestTokenSale(throwProxy).throwsWhenActivatingBeforeDeployingANT();
    throwProxy.assertThrows("Should have thrown when activating before deploying ANT");
  }

  function throwsWhenActivatingBeforeDeployingANT() {
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, address(this), address(this), 10 finney, 13 finney, 2);
    sale.activateSale();
  }

  function testCannotRedeployANT() {
    TestTokenSale(throwProxy).throwsWhenRedeployingANT();
    throwProxy.assertThrows("Should have thrown when redeploying ANT");
  }

  function throwsWhenRedeployingANT() {
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, address(this), address(this), 10 finney, 13 finney, 2);
    sale.deployANT(factory, true);
    sale.deployANT(factory, true);
  }

  function testOnlyMultisigCanDeployANT() {
    TestTokenSale(throwProxy).throwsWhenNonMultisigDeploysANT();
    throwProxy.assertThrows("Should have thrown when deploying ANT from not multisig");
  }

  function throwsWhenNonMultisigDeploysANT() {
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, 0x1, 0x3, 10 finney, 13 finney, 2);
    sale.deployANT(factory, true);
  }

  function testSetPresaleTokens() {
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, address(this), 0x2, 10 finney, 13 finney, 2);
    sale.deployANT(factory, true);
    sale.allocatePresaleTokens(0x1, 100);
    sale.allocatePresaleTokens(0x2, 50);
    Assert.equal(ERC20(sale.token()).balanceOf(0x1), 100, 'Should have correct balance after allocation');
    Assert.equal(ERC20(sale.token()).totalSupply(), 150, 'Should have correct supply after allocation');
  }

  function testCannotSetPresaleTokensAfterActivation() {
    TestTokenSale(throwProxy).throwIfSetPresaleTokensAfterActivation();
    throwProxy.assertThrows("Should have thrown when setting tokens after activation");
  }

  function throwIfSetPresaleTokensAfterActivation() {
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, address(this), address(this), 10 finney, 13 finney, 2);
    sale.deployANT(factory, true);
    sale.activateSale(); // this is both multisigs
    sale.allocatePresaleTokens(0x1, 100);
  }

  function testCannotSetPresaleTokensAfterSaleStarts() {
    TestTokenSale(throwProxy).throwIfSetPresaleTokensAfterSaleStarts();
    throwProxy.assertThrows("Should have thrown when setting tokens after sale started");
  }

  function throwIfSetPresaleTokensAfterSaleStarts() {
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, address(this), address(this), 10 finney, 13 finney, 2);
    sale.deployANT(factory, true);
    sale.setMockedBlockNumber(13);
    sale.allocatePresaleTokens(0x1, 100);
  }

  function testHasCorrectPriceForStages() {
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, address(this), address(this), 10 finney, 20 finney, 2);
    Assert.equal(sale.getPrice(10), 10 finney, "Should have correct price for start stage 1");
    Assert.equal(sale.getPrice(13), 10 finney, "Should have correct price for middle stage 1");
    Assert.equal(sale.getPrice(14), 10 finney, "Should have correct price for final stage 1");
    Assert.equal(sale.getPrice(15), 20 finney, "Should have correct price for start stage 2");
    Assert.equal(sale.getPrice(18), 20 finney, "Should have correct price for middle stage 2");
    Assert.equal(sale.getPrice(19), 20 finney, "Should have correct price for final stage 2");

    Assert.equal(sale.getPrice(9), 2**250, "Should have incorrect price out of sale");
    Assert.equal(sale.getPrice(20), 2**250, "Should have incorrect price out of sale");
  }

  function testHasCorrectPriceForMultistage() {
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 40, address(this), address(this), 10 finney, 30 finney, 3);
    Assert.equal(sale.getPrice(10), 10 finney, "Should have correct price");
    Assert.equal(sale.getPrice(19), 10 finney, "Should have correct price");
    Assert.equal(sale.getPrice(20), 20 finney, "Should have correct price");
    Assert.equal(sale.getPrice(25), 20 finney, "Should have correct price");
    Assert.equal(sale.getPrice(30), 30 finney, "Should have correct price");
    Assert.equal(sale.getPrice(39), 30 finney, "Should have correct price");

    Assert.equal(sale.getPrice(9), 2**250, "Should have incorrect price out of sale");
    Assert.equal(sale.getPrice(41), 2**250, "Should have incorrect price out of sale");
  }

}
