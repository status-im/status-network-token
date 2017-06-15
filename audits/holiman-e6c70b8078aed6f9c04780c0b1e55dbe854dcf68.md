These are some worknotes by Martin Holst Swende from looking into the Status.IM contracts, and does not constitute a full-scale audit. 

Exclusions are

- MiniMeToken.sol
- MultisigWallet.sol

Git commit: `e6c70b8078aed6f9c04780c0b1e55dbe854dcf68`. 

# Notes

## ContributionWallet

Holds a ref to a `multisig`. The multisig can request funds after a certain block; `endBlock`, which is set on creation. 

It will allow transfer if _either_ of these are true: 
- The blocknumber is after `endBlock`
- The `contribution` is `finalized`. 

Potential improvements: 

* Should check (upon creation) that `multisig` is a valid address
* Should check (upon creation) that `endBlock` is reasonably within bounds
* Should check (upon creation) that `contribution` is a valid address. 

## Owned

The `Owned` contract allows for setting `0x0` as owner. This may be dangerous. 
The `Owned` contract does a single-step transfer of ownership. Another, more secure model, is a two-step handover: 

1. `owner-> X.changeOwner(newOwner)`
  * `_futureOwner = newOwner`
2. `newOwner -> X.takeOwnership()`
  * `owner = _futureOwner; _futureOwner = 0x0`


## DevTokensHolder


This code does two external calls (`balanceOf`):

        uint256 balance = snt.balanceOf(address(this));
        uint256 total = collectedTokens.add(snt.balanceOf(address(this)));

Would save some gas if written as: 

        uint256 balance = snt.balanceOf(address(this));
        uint256 total = collectedTokens.add(balance);


---

This is a bit convoluted: 

        if (finalized == 0) throw;
        if (getTime().sub(finalized) <= months(6)) throw;

    ...

    function months(uint256 m) internal returns(uint256) {
        return m.mul(30 days);
    }

    function getTime() internal returns(uint256) {
        return now;
    }

Could be written more clearly as 

	assert (  finalized > 0 && now > finalized + 6 months )



---

If tokens or ether are mistakenly sent to `DevTokensHolder`, they can be recovered via `claimTokens`. 

The code casts the `_token` to a `MiniMeToken` - but the method can be used to extract any ERC20Token. In order to make this more clear, it would perhaps be better to include the `ERC20Token` interface, and do the cast to an `ERC20Token` instead.  

Applies to a few other contracts aswell, e.g. `StatusContribution`. 


## StatusContribution


`proxyPayment` does not verify that `address _th` is actually a valid address (!= `0`)

I'm not sure if having default function which buys tokens is a good idea; people may send money to if from contract wallets which are not capable of actually using the tokens afterwards. By forcing the use of a method, it's certain that the calling wallet can create arbitrary-data transactions. 



