## Before starting

* Install `yarn` and `npm`.
* Run `yarn` at the repo root.
* Use the same BIP39 compatible mnemonic in both `truffle.js` (can be set by environment variable `TEST_MNEMONIC`) and for your client.
* Change the `from` key in `truffle.js` for any network other than Ropsten or Kovan.
* Compile contracts:
  ```
  ./node_modules/.bin/truffle compile
  ```
* Start your Ethereum client:
  ```
  ./node_modules/.bin/testrpc --network-id 15 --mnemonic 'status mnemonic status mnemonic status mnemonic status mnemonic status mnemonic status mnemonic'
  ```

## Run tests

* Run tests
  ```
  ./node_modules/.bin/truffle test --network development
  ```

## Deploy

* Change the config constants in `migrations/2_deploy_contracts.js` to match your addresses and parameters.
* Deploy contracts (choose network from `truffle.js`). The following command deploys up to migration step 2:
  ```
  ./node_modules/.bin/truffle migrate --network development_migrate -f 2
  ```
