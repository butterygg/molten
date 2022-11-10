# 🌋 Molten finance

Molten Finance is a solution for two problems faced by DAOs:

1. Micro: DAO Financing or Governance Token Liquidity.
2. Macro: Plutocracy, or rule by the wealthy leading to governance failure.

## Summary

### Rationale

DAOs have taken on the difficult task of providing public goods without the financial flexibility
enjoyed by governments and, even worse, have a structural exposure to being ruled by the wealthy.

Left unaddressed, this represents a failure mode for DAOs, the effects of which could limit their
ultimate success. Should a user believe a public good’s governance may be biased against them, they
will limit their usage to avoid the costs they’ll incur should the rules be changed without their
consent. Flooding DAO governance with people who only care about “number go up” guarantees your DAO
will always choose to divert resources from things that support users to things that support token
price.

### Goals

DAOs enjoy more liquidity, specifically at size, for its governance tokens.

DAO governance is more inclusive and pluralistic, which leads to a reduction in the Gini
coefficient.

### Solution

- A DAO in need of finances.
- Minority constituencies within or outside of the DAO, whose preferences are underrepresented in DAO governance.
- Potential DAO Delegates (Candidates), in need of voting power.

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

**Note**: to test the oracle consulter, you will need a **Ethereum Mainnet RPC** node address to run the forked network tests. Such as from [Infura](http://infura.io/).

Once you have a mainnet RPC node url, set it to the `MAINNET_RPC_URL` variable in the `.env.example` file and rename the file to `.env`.

If you would like to **omit the oracle tests** then instead of `forge test` run

```bash
forge test --no-match-contract Oracle  # or --nmc for short
```

## The Oracle Consulter

The Oracle Consulter queries Uniswap V3's pool data, which the consulter processes to get the Time Weighted Average Price of the `token0` in a pool in terms of `token1`. In the case of Molten, it provides a TWAP price of a Dao's token in terms of a given quote token.

In other words, Uniswap V3 pools also acts as Oracles that provide price data to the Molten Oracle Consulter. Check out [Uniswap V3's docs](https://docs.uniswap.org/protocol/concepts/V3-overview/oracle) to learn more about this process.

### Deploying the Oracle Consulter

Ensure that you have set your `PRIVATE_KEY` in your local `.env` file to the private key of the network you'd like to deploy on.

Set the `MAINNET_RPC_URL` variable with the rpc url for Ethereum mainnet within your `.env` as well.

Then, run the `deployOracle.s.sol` script:

```bash
source .env
forge script script/deployOracle.s.sol --rpc-url $MAINNET_RPC_URL --broadcast -vvvv
```

If you'd like to verify to etherscan add the `ETHERSCAN_API_KEY` variable name to your `.env` and set it to your Etherscan api key.

Then run the script with the `--verify`:

```bash
source .env
forge script script/deployOracle.s.sol --rpc-url $MAINNET_RPC_URL --broadcast --verify -vvvv
```
