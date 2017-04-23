var AragonTokenSale = artifacts.require("AragonTokenSale");
var MiniMeTokenFactory = artifacts.require("MiniMeTokenFactory");
var ANPlaceholder = artifacts.require("ANPlaceholder");
var ANT = artifacts.require("ANT");
var MultiSigWallet = artifacts.require("MultiSigWallet");
var SaleWallet = artifacts.require("SaleWallet");

module.exports = function(deployer, network, accounts) {
  // if (network.indexOf('dev') > -1) return // dont deploy on tests

  const aragonMs = accounts[0]
  const communityMs = accounts[0]

  const initialBlock = 1014520
  const finalBlock = 1014550

  // cap is 1 eth for secret 1

  deployer.deploy(SaleWallet, aragonMs, finalBlock)
  deployer.deploy(MiniMeTokenFactory);
  deployer.deploy(AragonTokenSale, initialBlock, finalBlock, aragonMs, communityMs, 100, 66, 2, '0xdaa1cf71fb601ffe59f8ee702b6597cff2aba8d7a3c59f6f476f9afe353ba7b6')
    .then(() => {
      return MiniMeTokenFactory.deployed()
        .then(f => {
          factory = f
          return AragonTokenSale.deployed()
        })
        .then(s => {
          sale = s
          return SaleWallet.deployed()
        })
        .then(w => {
          wallet = w
          return ANT.new(factory.address)
        }).then(a => {
          ant = a
          return ant.changeController(sale.address)
        })
        .then(() => {
          return ANPlaceholder.new(sale.address, ant.address)
        })
        .then(networkPlaceholder => {
          return sale.setANT(ant.address, networkPlaceholder.address, wallet.address)
        })
    })
};
