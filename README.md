# 🌋 Molten

More details <a href="https://book.buttery.money/" target="_blank">here</a>.

## Molten funding contract

### Creation

A _Candidate_ for delegation creates the funding contract.

Main parameters are:

- Target DAO.
- Limit on deposits.
- Locking duration.

### Depositing

Depositing is allowed only until limit is reached and before exchange happens.

`deposit`: _Buyers_ deposit stablecoins.

`refund`: Buyers get refunded.

### Exchange

`exchange`: the _DAO_ treasury gets deposits in exchange for its governance tokens. Ideally, the
exchange rate given is at a discount on TWAP.

TWAP is determined via an oracle.

Importantly, DAO governance tokens are delegated to the Candidate.  
Basically, **Candidate get voting powers for the duration of the lock**.

mTokens are minted in equal amount as the governance tokens locked in the funding contract. Buyers
can claim their share of mTokens.

### Liquidation

`liquidate`: burn all mTokens and make governance tokens held in contract claimable again by Buyers.

Liquidation is freely executable once the locking period ended.  
Basically, **Buyers can redeem their mTokens for governance tokens once the lock ends**.

Liquidation can be triggered before the end of the locking period only by unanimous votes.

## Setup

```
forge build

forge test
```
