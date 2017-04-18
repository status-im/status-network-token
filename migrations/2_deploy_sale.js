var AragonTokenSale = artifacts.require("AragonTokenSale");
var MiniMeTokenFactory = artifacts.require("MiniMeTokenFactory");
var ANPlaceholder = artifacts.require("ANPlaceholder");
var ANT = artifacts.require("ANT");
var MultiSigWallet = artifacts.require("MultiSigWallet");

module.exports = function(deployer, network, accounts) {
  if (network.indexOf('dev') > -1) return // dont deploy on tests

  const realMS = "0x19050b771c18b9125629e73acbd7db44efad89a7"
  const testMS = accounts[0]// "0x538b3ef1eac22bdda9e649af2972c890ec2edec2"

  deployer.deploy(MiniMeTokenFactory);
  deployer.deploy(AragonTokenSale, 905350, 906350, testMS, accounts[0], 100, 66, 2)
    .then(() => {
      return MiniMeTokenFactory.deployed()
        .then(f => {
          factory = f
          return AragonTokenSale.deployed()
        })
        .then(s => {
          sale = s
          return ANT.new(factory.address)
        }).then(a => {
          ant = a
          return ant.changeController(sale.address)
        })
        .then(() => {
          return ANPlaceholder.new(sale.address, ant.address)
        })
        .then(networkPlaceholder => {
          return sale.setANT(ant.address, networkPlaceholder.address)
        })
    })
};
