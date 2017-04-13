pragma solidity ^0.4.8;

import "truffle/Assert.sol";
import "zeppelin/token/ERC20.sol";
import "./helpers/AragonTokenSaleMock.sol";
import "./helpers/ThrowProxy.sol";
import "./helpers/MultisigMock.sol";

contract TestTokenPresale {
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
    TestTokenPresale(throwProxy).throwIfStartPastBlocktime();
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
    TestTokenPresale(throwProxy).throwsWhenActivatingBeforeDeployingANT();
    throwProxy.assertThrows("Should have thrown when activating before deploying ANT");
  }

  function throwsWhenActivatingBeforeDeployingANT() {
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, address(this), address(this), 2, 1, 2);
    sale.activateSale();
  }

  function testCannotRedeployANT() {
    TestTokenPresale(throwProxy).throwsWhenRedeployingANT();
    throwProxy.assertThrows("Should have thrown when redeploying ANT");
  }

  function throwsWhenRedeployingANT() {
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, address(this), address(this), 2, 1, 2);
    sale.deployANT(factory, true);
    sale.deployANT(factory, true);
  }

  function testOnlyMultisigCanDeployANT() {
    TestTokenPresale(throwProxy).throwsWhenNonMultisigDeploysANT();
    throwProxy.assertThrows("Should have thrown when deploying ANT from not multisig");
  }

  function throwsWhenNonMultisigDeploysANT() {
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, 0x1, 0x3, 2, 1, 2);
    sale.deployANT(factory, true);
  }

  function testSetPresaleTokens() {
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, address(this), 0x2, 2, 1, 2);
    sale.deployANT(factory, true);
    sale.allocatePresaleTokens(0x1, 100 finney, uint64(now + 12 weeks), uint64(now + 24 weeks));
    sale.allocatePresaleTokens(0x2, 30 finney, uint64(now + 12 weeks), uint64(now + 24 weeks));
    sale.allocatePresaleTokens(address(this), 20 finney, uint64(now + 12 weeks), uint64(now + 24 weeks));
    Assert.equal(ERC20(sale.token()).balanceOf(0x1), 100 finney, 'Should have correct balance after allocation');
    Assert.equal(IrrevocableVestedToken(sale.token()).transferableTokens(0x1, uint64(now)), 0, 'Should have 0 tokens transferable now');
    Assert.equal(IrrevocableVestedToken(sale.token()).transferableTokens(0x1, uint64(now + 12 weeks - 1)), 0, 'Should have 0 tokens transferable just before cliff');
    Assert.equal(IrrevocableVestedToken(sale.token()).transferableTokens(0x1, uint64(now + 12 weeks)), 50 finney, 'Should have some tokens transferable after cliff');
    Assert.equal(IrrevocableVestedToken(sale.token()).transferableTokens(0x1, uint64(now + 18 weeks)), 75 finney, 'Should have some tokens transferable during vesting');
    Assert.equal(IrrevocableVestedToken(sale.token()).transferableTokens(0x1, uint64(now + 21 weeks)), 87500 szabo, 'Should have some tokens transferable during vesting');
    Assert.equal(IrrevocableVestedToken(sale.token()).transferableTokens(0x1, uint64(now + 24 weeks)), 100 finney, 'Should have all tokens transferable after vesting');
    Assert.equal(ERC20(sale.token()).totalSupply(), 150 finney, 'Should have correct supply after allocation');

    Assert.equal(ERC20(sale.token()).balanceOf(this), 20 finney, 'Should have correct balance');
    TestTokenPresale(throwProxy).throwsWhenTransferingPresaleTokensBeforeCliff(sale.token());
    throwProxy.assertThrows("Should have thrown when transfering presale tokens");
  }

  function throwsWhenTransferingPresaleTokensBeforeCliff(address token) {
    ERC20(token).transfer(0xdead, 1);
  }

  function testCannotSetPresaleTokensAfterActivation() {
    TestTokenPresale(throwProxy).throwIfSetPresaleTokensAfterActivation();
    throwProxy.assertThrows("Should have thrown when setting tokens after activation");
  }

  function throwIfSetPresaleTokensAfterActivation() {
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, address(this), address(this), 2, 1, 2);
    sale.deployANT(factory, true);
    sale.activateSale(); // this is both multisigs
    sale.allocatePresaleTokens(0x1, 100, uint64(now + 12 weeks), uint64(now + 24 weeks));
  }

  function testCannotSetPresaleTokensAfterSaleStarts() {
    TestTokenPresale(throwProxy).throwIfSetPresaleTokensAfterSaleStarts();
    throwProxy.assertThrows("Should have thrown when setting tokens after sale started");
  }

  function throwIfSetPresaleTokensAfterSaleStarts() {
    AragonTokenSaleMock sale = new AragonTokenSaleMock(10, 20, address(this), address(this), 2, 1, 2);
    sale.deployANT(factory, true);
    sale.setMockedBlockNumber(13);
    sale.allocatePresaleTokens(0x1, 100, uint64(now + 12 weeks), uint64(now + 24 weeks));
  }
}
