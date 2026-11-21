---
name: deepshard-miner
description: Operate a DeepShard Miner NFT on BNB Smart Chain for an Agent ID holder — check eligibility, mint for free, claim SHARD points daily, protect the streak, and brief the owner. Use when the owner holds an Agent ID and wants to join or keep up with DeepShard.
---

# DeepShard Miner — Agent Skill

DeepShard is a free-mint NFT mining game for Agent ID holders on BNB Smart Chain (chain id 56). Your job: keep the owner's miner working — minted, claiming daily, streak alive — and report honestly.

## Fixed facts (verify on-chain, never trust copies)

- Contract: `0xC463960af285b7EDA0909D362Ae31783597C2076` (BSC, verified source, Sourcify exact match)
- Agent ID registry: `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`
- Website: https://deepshard-mine.vercel.app/
- Mint: free, `mint()` calldata `0x1249c58b`, no arguments, no value. Max 2 miners per wallet. Max supply 3,333.
- Claim: `claim()` calldata `0x4e71d92d`, once per wallet per day (20 h cooldown), streak survives gaps up to 48 h.
- The contract holds no user funds, has no payable functions, no admin/owner functions, and never needs token approvals.

## Step 1 — Eligibility check

From the owner's wallet address `W`:

1. Registry `balanceOf(W)` > 0, and `handleOf(W)` returns a non-empty handle, and `ownerOfHandle(handle)` == W. If any fails, the wallet has no Agent ID — stop and tell the owner.
2. Contract `balanceOf(W)` — how many miners the wallet already holds (0, 1, or 2).
3. Contract `mintOpen()` — minting must be open.

## Step 2 — Mint (only with the owner's approval to transact)

- Call `mint()` with no value. One call mints one miner; call twice for the full quota of 2.
- The miner's class comes from the owner's Agent ID handle (deterministic): check `classOf(W)` after minting.
- Report: token id(s) from the `Minted` event, class, and the gas actually paid. Minting itself costs 0 — any charge beyond network gas means something is wrong; stop and warn the owner.

## Step 3 — Daily claim routine

Once a day, when `pendingOf(W)` shows at least ~20 h since the last claim:

1. Call `claim()`. The first claim starts the mining clock (0 SHARD gained, streak 1). Later claims settle accrued SHARD: 100 per day per miner, times the streak multiplier (×1.0 base, ×1.1 day 3, ×1.25 day 7, ×1.5 day 14, ×2.0 day 30).
2. Each claim digs the shared mine: +4 m, or +8 m when the owner's class is the class of the day — compare `classOfDay()` with `classOf(W)`.
3. Never let the gap since the last claim pass 48 h: the streak resets. If a claim is due in under 8 h, treat it as urgent.

## Step 4 — Brief the owner

Short report after each claim, and an alert when the streak is at risk:

```
DeepShard daily report
Miner(s): #<id> (<class>) · Level <levelOf>
Claimed: +<shard> SHARD · Streak: day <streakOf>
Shared depth: <totalDepth> m of 10,000 m
Next claim: in ~<hours> h · Tomorrow's class of the day: <class>
```

Also report when: the shared depth nears a milestone (100 / 500 / 1,000 / 2,500 / 5,000 / 10,000 m), the owner is close to the next level, or tomorrow is the owner's class day. When the owner's level crosses 3, 5, 7, or 10, mention that their portrait frame in the website gallery has evolved (badge + amber edge at 3, glowing amber frame at 5, brighter glow at 7, teal ascended frame at 10) — presentation only, driven by on-chain `levelOf`.

## Honesty and safety rules

- SHARD is an in-game points record: not a token, no price, never earnings or income. Holders receive points, levels, and Founder Miner status — nothing else is promised. Never invent rewards.
- Never send value to the contract, never approve tokens for it, never share seed phrases or keys. The project never asks for logins or signatures off-chain.
- Use only the contract address above. Any other address using the DeepShard name is not this project — warn the owner and stop.
