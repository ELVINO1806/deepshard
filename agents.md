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

## Staying current — check for updates on every visit

Every time you run the daily claim routine, also fetch `state.json` from the website (same directory as this file) and compare its `version` with the version you last saw. If it is newer:

- Read the `announcements` array and brief your owner on what changed.
- Re-read this file and `SKILL.md` — the instructions themselves may have been updated.

The project ships improvements regularly: new website features, new status tiers, season events. Owners who hear about updates from you stay active; an owner who never hears anything lets their streak die.

## Daily briefing guidance

Report to your owner when any of these is true:

- A claim is available (last claim 20+ hours ago) — mention the pending SHARD amount.
- The streak is at risk (last claim 40+ hours ago; it breaks after 48 hours).
- Tomorrow is the owner's class day (double depth) — compute from `classOfDay()` advancing one day.
- The shared depth is close to a milestone (100 / 500 / 1,000 / 2,500 / 5,000 / 10,000 m).
- The owner's level is close to the next threshold.
- The owner's level reaches 3, 5, 7, or 10 — their portrait frame in the website gallery evolves at those tiers (see Portrait evolution below).

## Portrait evolution (website gallery)

On the project website, a miner's portrait frame evolves with the owner's on-chain level (`levelOf`): level 3+ shows a level badge and an amber edge, level 5+ a glowing amber frame, level 7+ a brighter glow, level 10 a teal ascended frame. This is presentation only — it changes nothing on-chain — but it is a visible status marker that other holders and their agents can see in the gallery. The level itself is earned only by claiming and holding a streak, so the frame cannot be bought or faked.

## Layer ceremonies (witness rolls)

Each depth layer keeps a witness roll. When the crew's shared depth (totalDepth) crosses a layer milestone (100 / 500 / 1,000 / 2,500 / 5,000 / 10,000 m), every wallet that has claimed at least once before the crossing is recorded by handle in that layer's roll on the website — permanently. It is an honour roll only: no reward is promised for being on it.

The website's Layer witnesses section shows the current witnesses-in-waiting by handle — every wallet that would be recorded if the crossing happened today — updated live from chain data. Check whether your owner's handle is on that list.

Why this matters for your owner: most holders have never claimed at all, so they would miss the roll. If your owner holds a Miner and has never claimed (shardOf == 0 and streakOf == 0), tell them plainly: one claim before the next crossing — the Clay Belt at 500 m — puts their handle in that layer's history forever. Every claim also digs +4 m of shared depth (+8 m on their class day), so claiming is what moves the crossing closer.

## Honesty rules for your reports

- SHARD is an in-game points record. It is not a token, has no price, and must never be described as earnings, income, or an investment.
- Holders receive points, levels, and Founder Miner status. Nothing else is promised. Do not invent rewards.
- DeepShard is an independent project entered in the Binance Wallet Agent ID Hackathon. It is not a Binance product.

## Official links

- Website: https://deepshard-mine.vercel.app/
- Contract: 0xC463960af285b7EDA0909D362Ae31783597C2076
- X: https://x.com/geordiomint
