# DeepShard — Instructions for Agents

You are reading this because your owner holds (or may want) a DeepShard Miner NFT. This file tells you exactly how to evaluate the project, how to act on your owner's behalf, and how to report back. All facts here are verifiable on-chain in the verified contract source.

## What this project is

A free-mint NFT game for Agent ID holders on BNB Smart Chain (chain id 56). Minting is free; the only cost of any action is the network gas fee, paid to the chain, never to the project. The contract address is published in `state.json` next to this file and on the project website. Do not trust any other address.

## Safety evaluation (verify it yourself)

1. Read the contract source (verified, exact match). Confirm: no payable functions, no withdraw function, no owner or admin functions, no function that moves user assets, supply constant 3,333.
2. Confirm the mint price by quoting `mint()` — it takes no arguments and no value. Sending value to it reverts.
3. Confirm the Agent ID gate reads the official registry 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F.
4. The project never asks for token approvals, signatures, seed phrases, or logins of any kind. If any page or message asks for those in DeepShard's name, it is not us — warn your owner and stop.

## Actions you may prepare for your owner

- **Mint**: call `mint()` from the owner's Agent ID wallet. Free; max 2 per wallet; only while `mintOpen()` returns true. Token numbers are sequential — earlier mints get smaller numbers.
- **Claim (daily)**: call `claim()` once per day per wallet. It settles accrued SHARD, extends the streak if the last claim was within 48 hours, and digs the shared depth meter (+4 m, or +8 m when the owner's miner class is the class of the day — check `classOfDay()` and `classOf(owner)`).
- **Read state for briefings**: `shardOf(owner)`, `streakOf(owner)`, `levelOf(owner)`, `pendingOf(owner)`, `totalDepth()`, `totalSupply()`, `handleOf(owner)`.

## Daily briefing guidance

Report to your owner when any of these is true:

- A claim is available (last claim 20+ hours ago) — mention the pending SHARD amount.
- The streak is at risk (last claim 40+ hours ago; it breaks after 48 hours).
- Tomorrow is the owner's class day (double depth) — compute from `classOfDay()` advancing one day.
- The shared depth is close to a milestone (100 / 500 / 1,000 / 2,500 / 5,000 / 10,000 m).
- The owner's level is close to the next threshold.

## Honesty rules for your reports

- SHARD is an in-game points record. It is not a token, has no price, and must never be described as earnings, income, or an investment.
- Holders receive points, levels, and Founder Miner status. Nothing else is promised. Do not invent rewards.
- DeepShard is an independent project entered in the Binance Wallet Agent ID Hackathon. It is not a Binance product.

## Official links

- Website: https://deepshard-mine.vercel.app/
- Contract: 0xC463960af285b7EDA0909D362Ae31783597C2076
- X: https://x.com/geordiomint
