# Status Multisig structure

Having a good multisig structure is important for security, SNT holders' trust and ensuring the project can and will do everything as planned.

The Status offering will feature two multisigs: The StatusDev Multisig (Status core developers) and the Community Multisig.

Both use Gnosis Multisig at commit [25fba5](https://github.com/ConsenSys/gnosis-contracts/blob/25fba563d95bbc8361c7de75801c38ce368cab85/contracts/solidity/Wallets/MultiSigWallet.sol) which was independentely audited. Status multisigs were compiled using Solidity v0.4.8 with optimization disabled.

## StatusDev Multisig – Café Latte [0x](https://etherscan.io/address/0xcafelatte)

#### Required signatures: 2/4

#### Signers:

- Jarrad Hope, Status Cofounder. [0x](https://etherscan.io/address/0x) – [Proof](https://etherscan.io/tx/0x)
- Carl Bennetts, Status Cofounder. [0x](https://etherscan.io/address/0x) – [Proof](https://etherscan.io/tx/0x5aaeb2d0361dbdf3b4ecadad1b49c239eb1b3b5e1cf973f6a4597ad56edc47b9).
- Community Multisig – [0x](https://etherscan.io/address/0x)
- Recovery address, recoverable only by both Jarrad and Carl – TBD – Pending proof by Jarrad and Carl.


#### Responsibilities

- The StatusDev multisig will be the address responsible to control the whole contribution period process.
- It will hold the Aragon Foundation ether funds and SNT tokens. It will make the token allocations for founders and early contributors.

#### Rationale

- Even though it is a 2/4 multisig it really is a 2/3, because the recovery key can only be constructed if Jarrad and Carl get together to do so. No one can individually recover it, not even the undisclosed trusted person that will be the keeper of the hardware wallet containing the key. It is only as a security measure in the very unfortunate case that either Carl or Jarrad lose their key (they will be losing access to all their SNT).
- The decision to introduce the Community Multisig is that in case of a disagreement between Carl or Jarrad, no one can extort the other part into locking the multisig forever. With support from the Community Multisig, whoever has the project and community best interests at hFeart and can convince the community, will be able to kick the other founder out of the multisig, and the project will continue its course.



## Community multisig – Beef beef [0xbeefbeef](https://etherscan.io/address/0xbeefbeef)

#### Required signatures: 3/5

#### Signers

- StatusDev multisig. [0xcafe1a77e84698c83ca8931f54a755176ef75f2c](https://etherscan.io/address/0xcafe1a77e84698c83ca8931f54a755176ef75f2c)
- Joe Urgo, CEO [Sourcerers](http://sourcerers.io) & [Dapp daily](https://dappdaily.com) author. [0x75d83a0ae1543fd4b49594023977e1daf5a954c5](https://etherscan.io/address/0x75d83a0ae1543fd4b49594023977e1daf5a954c5) – [Proof](https://etherscan.io/tx/0x796538ed7dd4d76953b045c6341129f8976fefeb160de72618dc28c50138cc5a)

#### Pending signers

- Pending 1
- Pending 2
- Pending 3

#### Responsibilities

- The community multisig will serve SNT holders and the broader crypto community to ensure Status's stated mission is carried.
- The community multisig will be responsible for deploying the Status Network code (provided by StatusDev) once it is considered secure to do it and it matches the original expectations of it.
- Solving hypothetic deadlock problems in the StatusDev multisig to ensure resources won't get locked and the project will continue its course.

#### Rationale

- Deploying the Status Network is a huge responsibility, and that's why we consider it a community effort. StatusDev will provide the bytecode for such network, but without support from the community it won't be deployed.

- In case of a deadlock, the multisig will be a 4/6 multisig assuming that the StatusDev cannot sign. Support from the community multisig this plus one of the founders can solve the deadlock.
