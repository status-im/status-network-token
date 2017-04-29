# SNT Initial Offering flow

Example of a successful testnet offering: https://kovan.etherscan.io/address/0x506E1db7DA1B3876eAcd2EdDf6ED551A7F2787D0

### Instantiation

#### 1. Deploy offering – 1,425,663 gas
Status contribution period will be deployed 1 week prior to the beginning of the offering with the following parameters:

- Initial block: TBC
- Final block: Initial block + 172,800 (4 weeks)
- Status Dev Multisig: TBC (2/3 confirms multisig with Jorge, Luis, Security key that can only be reconstructed by Jorge and Luis).
- Community Multisig: TBC (3/5 confirms with Status Dev Multisig + 4 trusted members of community)
- Initial price: 100
- Final price: 66
- Price stages: 2
- Cap commitment: sealed commitment for the soft hidden cap.

#### 2. offering.setSNT() – 95,427 gas
Set SNT needs to called from the Status Multisig. Its parameters are:

- SNT token address: An empty deployed instance of SNT.
- SNPlaceholder: A network placeholder with references to the Offering and SNT.
- Offering wallet: A contract that holds offering funds until final block.

Status Dev will perform setSNT inmediately after deploying the offering so it is instantiated as soon as possible.

After deploySNT has been called, the offering contract will have two public addresses available:

- token: The address of the official MiniMe ERC20 compatible Status Network Token.
- networkPlaceholder: The placeholder for the Status Network until its deployment.

The offering will be the token controller during the offering. After the offering it will be the network placeholder.

Status Dev will at this point prove the source code of the contracts in blockchain explorers.

### Preoffering

The preoffering is the period between full offering instantiation to the initialBlock of the offering.

During the preoffering it is required that the offering is activated, failing to activate the offering during this period, will cause the offering to never start.

#### 3. offering.allocatePreofferingTokens() – 209,075 gas

Status dev will be able to allocate at its own discretion as many preoffering tokens as needed before the offering is activated.

Status dev will only issue preoffering token to preoffering partners that took part in a private offering done for gathering the funds needed for the offering.

Preoffering tokens have cliff and vesting for avoiding market dumps.

#### 4. offering.activateOffering() – 2 * 42,862 gas

Both Status Dev and the Community Multisig must call activateOffering in order to consider the offering activated.

When both multisigs have called this function, the offering will be activated and no more preoffering allocations will be allowed.

### Offering

If the preoffering is successful in activating the offering, the offering will start on the initial block.

#### 5. Buy tokens offering.fallback || token.fallback – 108,242 gas || 118,912 gas

After the offering is started, sending an ether amount greater than the dust value (1 finney) will result in tokens getting minted and assigned to the sender of the payment.

All the funds collected will be instantly sent to the Status Dev multisig for security.

Disclaimer: Please do not send from exchanges.

<img src="rsc/snt_buy.png"/>

#### 6. offering.emergencyStopOffering() – 43,864 gas

After the offering is activated, Status Dev will be able to stop the offering for an emergency.

#### 7. offering.restartOffering() – 14,031 gas

After the offering has been stopped for an emergency and the offering is still ongoing, Status Dev will be able to restart it.

After the offering has ended, it cannot be restarted. The offering can end in a stopped state without problem, but if enabled to restart after ending it could allow Status Dev to block the deployment of the network by the community multisig.

### After offering

The after offering period is considered from the final block (inclusive) until the offering contract is destroyed.

#### 8. offering.finalizeOffering() – 105,348 gas

This method will mint an additional 3/7 of tokens so at the end of the offering Status Dev will own 30% of all the SNT supply.

In the process of doing so, it will make the SNPlaceholder the controller of the token contract. Which will make the token supply be constant until the network is deployed and it implements a new minting policy.

#### 9. offering.deployNetwork() – 22, 338 gas

After the offering is finalized, the community multisig will be able to provide the address of the already deployed Status Network.

The SNPlaceholder will transfer its Token Controller power and it will be able to mint further tokens if the network governance decides so.

The offering contract is now suicided in favor of the network, though it shouldn't have any ether.

<img src="rsc/sn_deploy.png"/>

### Token operations

#### transfer – 95,121 gas
#### grantVestedTokens – 163,094 gas
