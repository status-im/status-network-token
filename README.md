# Status Network Token

- [Whitepaper](https://status.im/whitepaper.pdf)
- [Contribution Period Specification](/SPEC.md)
- [The Importance of Distribution](https://blog.status.im/TODO) blogpost.
- [Encoding the Status ‘Genesis Block’](https://blog.status.im/encoding-the-status-genesis-block-d73d287a750) blogpost.

## Technical definition

At the technical level SGT & SNT are a ERC20-compliant tokens, derived from the [MiniMe Token](https://github.com/Giveth/minime) that allows for token cloning (forking), which will be useful for many future use-cases.

Also built in the token is a vesting schedule for limiting SNT transferability over time. Status Project Founders tokens are vesting.

## Contracts

- [SNT.sol](/contracts/SNT.sol): Main contract for the token.
- [SGT.sol](/contracts/SGT.sol): Token contract for early adopters. Deployed to [0xd248B0D48E44aaF9c49aea0312be7E13a6dc1468](https://etherscan.io/address/0xd248B0D48E44aaF9c49aea0312be7E13a6dc1468#readContract)
- [MiniMeToken.sol](/contracts/MiniMeToken.sol): Token implementation.
- [StatusContribution.sol](/contracts/StatusContribution.sol): Implementation of the initial distribution of SNT.
- [DynamicCeiling.sol](/contracts/DynamicCeiling.sol): Auxiliary contract to manage the dynamic ceiling during the contribution period.
- [SNTPlaceholder.sol](/contracts/SNPlaceholder.sol): Placeholder for the Status Network before its deployment.
- [ContributionWallet.sol](/contracts/ContributionWallet.sol): Simple contract that will hold all funds until final block of the contribution period.
- [MultiSigWallet.sol](/contracts/MultiSigWallet.sol): Gnosis multisig used for Status and community multisigs.
- [DevTokensHolder.sol](/contracts/DevTokensHolder.sol): Contract where tokens belonging to developers will be held. This contract will release this tokens in a vested timing.
- [SGTExchanger.sol](/contracts/MultiSigWallet.sol): Contract responsible for crediting SNTs to the SGT holders after the contribution period ends.

## Reviewers and audits.

Code for the SNT token and the offering has been reviewed by:

- Jordi Baylina, Author.
- Smart Contract Solutions (OpenZeppelin). [Pending audit results](/)
- YYYYYY. [Pending audit results](/)

A bug bounty for the SNT token and offering started on [pending date]. More details.
