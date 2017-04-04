# Sale flow

Sale ABI:

```
[{"constant":true,"inputs":[],"name":"initialPrice","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"finalBlock","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"emergencyStopSale","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"aragonNetwork","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"initialBlock","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"communityMultisig","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_blockNumber","type":"uint256"}],"name":"stageForBlock","outputs":[{"name":"","type":"uint8"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"getBlockNumber","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"saleStopped","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_to","type":"address"},{"name":"_amount","type":"uint256"}],"name":"onTransfer","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"isActivated","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"finalizeSale","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"priceStages","outputs":[{"name":"","type":"uint8"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_newMultisig","type":"address"}],"name":"setCommunityMultisig","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"restartSale","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"activated","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_receiver","type":"address"},{"name":"_amount","type":"uint256"}],"name":"allocatePresaleTokens","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_factory","type":"address"},{"name":"_testMode","type":"bool"}],"name":"deployANT","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"n","type":"uint8"}],"name":"addressForContract","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"finalPrice","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"activateSale","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"aragonDevMultisig","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_stage","type":"uint8"}],"name":"priceForStage","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_networkCode","type":"bytes"}],"name":"deployNetwork","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_newMultisig","type":"address"}],"name":"setAragonDevMultisig","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"},{"name":"_amount","type":"uint256"}],"name":"onApprove","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"totalCollected","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_blockNumber","type":"uint256"}],"name":"getPrice","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_owner","type":"address"}],"name":"proxyPayment","outputs":[{"name":"","type":"bool"}],"payable":true,"type":"function"},{"constant":true,"inputs":[],"name":"dust","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"token","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"inputs":[{"name":"_initialBlock","type":"uint256"},{"name":"_finalBlock","type":"uint256"},{"name":"_aragonDevMultisig","type":"address"},{"name":"_communityMultisig","type":"address"},{"name":"_initialPrice","type":"uint256"},{"name":"_finalPrice","type":"uint256"},{"name":"_priceStages","type":"uint8"}],"payable":false,"type":"constructor"},{"payable":true,"type":"fallback"}]
```


ANT token ABI:

```[{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_amount","type":"uint256"}],"name":"approve","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"creationBlock","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_to","type":"address"},{"name":"_amount","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_newController","type":"address"}],"name":"changeController","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_blockNumber","type":"uint256"}],"name":"balanceOfAt","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_data","type":"bytes"}],"name":"rightPad","outputs":[{"name":"","type":"bytes"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"version","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_cloneTokenName","type":"string"},{"name":"_cloneDecimalUnits","type":"uint8"},{"name":"_cloneTokenSymbol","type":"string"},{"name":"_snapshotBlock","type":"uint256"},{"name":"_transfersEnabled","type":"bool"}],"name":"createCloneToken","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"parentToken","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_owner","type":"address"},{"name":"_amount","type":"uint256"}],"name":"generateTokens","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_blockNumber","type":"uint256"}],"name":"totalSupplyAt","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_amount","type":"uint256"}],"name":"transfer","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"transfersEnabled","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"parentSnapShotBlock","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_amount","type":"uint256"},{"name":"_extraData","type":"bytes"}],"name":"approveAndCall","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_owner","type":"address"},{"name":"_amount","type":"uint256"}],"name":"destroyTokens","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"}],"name":"allowance","outputs":[{"name":"remaining","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"tokenFactory","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_transfersEnabled","type":"bool"}],"name":"enableTransfers","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"controller","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"inputs":[{"name":"_tokenFactory","type":"address"},{"name":"_parentToken","type":"address"},{"name":"_parentSnapShotBlock","type":"uint256"},{"name":"_tokenName","type":"string"},{"name":"_decimalUnits","type":"uint8"},{"name":"_tokenSymbol","type":"string"},{"name":"_transfersEnabled","type":"bool"}],"payable":false,"type":"constructor"},{"payable":true,"type":"fallback"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_from","type":"address"},{"indexed":true,"name":"_to","type":"address"},{"indexed":false,"name":"_amount","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_cloneToken","type":"address"},{"indexed":false,"name":"_snapshotBlock","type":"uint256"}],"name":"NewCloneToken","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_owner","type":"address"},{"indexed":true,"name":"_spender","type":"address"},{"indexed":false,"name":"_amount","type":"uint256"}],"name":"Approval","type":"event"}]
```

Example of a successful testnet sale: https://kovan.etherscan.io/address/0x4f9b457a22df8eea5e4170171f609ea4d200a9ea

## Instantiation

### 1. Deploy sale:
Aragon token sale will be deployed 1 week prior to the beggining of the sale with the following parameters:

- Initial block: TBC
- Final block: Initial block + 172,800 (4 weeks)
- Aragon Dev Multisig: TBC (2/3 confirms multisig with Jorge, Luis, Security key that can only be reconstructed by Jorge and Luis).
- Community Multisig: TBC (3/5 confirms with Aragon Dev Multisig + 4 trusted members of community)
- Initial price: 100
- Final price: 66
- Price stages: 2

### 2. sale.deployANT()
Deploy ANT needs to called from the Aragon Multisig. Its parameters are:

- Factory: TBC (A mainnet deployed instance of MiniMe Token Factory)
- isTest: False (So it checks the address is correct)

Aragon Dev will perform deployANT inmediately after deploying the sale so it is instantiated as soon as possible.

After deployANT has been called, the sale contract will have two public addresses available:

- token: The address of the official MiniMe ERC20 compatible Aragon Network Token.
- aragonNetwork: The address that the Aragon Network will have in the future.

The sale will be the token controller during the sale.

Aragon Dev will at this point prove the source code of the contracts in blockchain explorers.

## Presale

The presale is the period between full sale instantiation to the initialBlock of the sale.

During the presale it is required that the sale is activated, failing to activate the sale during this period, will cause the sale to never start.

### 3. sale.allocatePresaleTokens()

Aragon dev will be able to allocate at its own discretion as many presale tokens as needed before the sale is activated.

Aragon dev will only issue presale token to presale partners that took part in a private sale done for gathering the funds needed for the sale.

### 4. sale.activateSale()

Both Aragon Dev and the Community Multisig must call activateSale in order to consider the sale activated.

When both multisigs have called this function, the sale will be activated and no more presale allocations will be allowed.

## Sale

If the presale is successful in activating the sale, the sale will start on the initial block.

### 5. sale.fallback || token.fallback

After the sale is started, sending an ether amount greater than the dust value (1 finney) will result in tokens getting minted and assigned to the sender of the payment.

All the funds collected will be instantly sent to the Aragon Dev multisig for security.

Disclaimer: Please do not send from exchanges.

### 6. sale.emergencyStopSale()

After the sale is activated, Aragon Dev will be able to stop the sale for an emergency.

### 7. sale.restartSale()

After the sale has been stopped for an emergency and the sale is still ongoing, Aragon Dev will be able to restart it.

After the sale has ended, it cannot be restarted. The sale can end in a stopped state without problem, but if enabled to restart after ending it could allow Aragon Dev to block the deployment of the network by the community multisig.

## After sale

The after sale period is considered from the final block (inclusive) until the sale contract is destroyed.

### 8. sale.finalizeSale()

This method will mint an additional 33% of tokens so at the end of the sale Aragon Dev will own 25% of all the ANT.

In the process of doing so, it will make the Aragon Network the controller of the token contract. Which will make the token supply be constant until the network is deployed and it implements a new minting policy.

### 9. sale.deployNetwork

After the sale is finalized, the community multisig will be able to provide the bytecode for deploying the network at the already known address.

The network will already be the Token Controller and will be able to mint further tokens if the network governance decides so.

The sale contract is now suicided in favor of the network, though it shouldn't have any ether.
