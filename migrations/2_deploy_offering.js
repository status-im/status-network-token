var StatusContributionPeriod = artifacts.require("StatusContributionPeriod");
var MiniMeTokenFactory = artifacts.require("MiniMeTokenFactory");
var SNPlaceholder = artifacts.require("SNPlaceholder");
var SNT = artifacts.require("SNT");
var MultiSigWallet = artifacts.require("MultiSigWallet");
var OfferingWallet = artifacts.require("OfferingWallet");

module.exports = function(deployer, network, accounts) {
  // if (network.indexOf('dev') > -1) return // dont deploy on tests

  const statusMs = accounts[0]
  const communityMs = accounts[0]

  const initialBlock = 1014520
  const finalBlock = 1014550

  // cap is 1 eth for secret 1

  deployer.deploy(OfferingWallet, statusMs, finalBlock)
  deployer.deploy(MiniMeTokenFactory);
  deployer.deploy(StatusContributionPeriod, initialBlock, finalBlock, statusMs, communityMs, 100, 66, 2, '0xdaa1cf71fb601ffe59f8ee702b6597cff2aba8d7a3c59f6f476f9afe353ba7b6')
    .then(() => {
      return MiniMeTokenFactory.deployed()
        .then(f => {
          factory = f
          return StatusContributionPeriod.deployed()
        })
        .then(s => {
          offering = s
          return OfferingWallet.deployed()
        })
        .then(w => {
          wallet = w
          return SNT.new(factory.address)
        }).then(a => {
          ant = a
          return ant.changeController(offering.address)
        })
        .then(() => {
          return ant.setCanCreateGrants(offering.address, true)
        })
        .then(() => {
          return ant.changeVestingWhitelister(statusMs)
        })
        .then(() => {
          return SNPlaceholder.new(offering.address, ant.address)
        })
        .then(networkPlaceholder => {
          return offering.setSNT(ant.address, networkPlaceholder.address, wallet.address)
        })
    })
};
