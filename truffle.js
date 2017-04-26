require('babel-register');
require('babel-polyfill');

var HDWalletProvider = require('truffle-hdwallet-provider');

const mnemonic = process.env.TEST_MNETONIC;
const ropstenProvider = new HDWalletProvider(mnemonic, 'https://ropsten.infura.io/');
const kovanProvider = new HDWalletProvider(mnemonic, 'https://kovan.aragon.one');

module.exports = {
  networks: {
    development: {
      network_id: 15,
      host: 'localhost',
      port: 8545,
      gas: 1e8,
    },
    test: {
     provider: require('ethereumjs-testrpc').provider({ gasLimit: 100000000 }),
     network_id: "*"
   },
   development46: {
     network_id: 15,
     host: 'localhost',
     port: 8546,
     gas: 8e7,
   },
    ropsten: {
      network_id: 3,
      provider: ropstenProvider,
      gas: 4.712e6,
    },
    kovan: {
      network_id: 42,
      provider: kovanProvider,
      gas: 4.99e6,
    },
  },
  build: {},
}
