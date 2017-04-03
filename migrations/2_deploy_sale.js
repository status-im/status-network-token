var AragonTokenSale = artifacts.require("AragonTokenSale");
var MiniMeTokenFactory = artifacts.require("MiniMeTokenFactory");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(MiniMeTokenFactory);
  deployer.deploy(AragonTokenSale, 1000000, 10000000, accounts[2], accounts[1], 2, 5, 2)
    .then(() => {
      return MiniMeTokenFactory.deployed()
        .then(f => {
          factory = f
          return AragonTokenSale.deployed()
        })
        .then(sale => sale.deployANT(factory.address, network.indexOf('dev') > -1, { from: accounts[2] }))
    })
};
