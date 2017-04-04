var AragonTokenSale = artifacts.require("AragonTokenSale");
var MiniMeTokenFactory = artifacts.require("MiniMeTokenFactory");
var MultiSigWallet = artifacts.require("MultiSigWallet");

module.exports = function(deployer, network, accounts) {

  const realMS = "0x19050b771c18b9125629e73acbd7db44efad89a7"
  const testMS = accounts[0]// "0x538b3ef1eac22bdda9e649af2972c890ec2edec2"

  deployer.deploy(MiniMeTokenFactory);
  deployer.deploy(AragonTokenSale, 663250, 663280, testMS, accounts[0], 100, 66, 2)
    .then(() => {
      return MiniMeTokenFactory.deployed()
        .then(f => {
          factory = f
          return AragonTokenSale.deployed()
        })
        .then(sale => sale.deployANT(factory.address, network.indexOf('dev') > -1, { from: accounts[0] }))
    })
};
