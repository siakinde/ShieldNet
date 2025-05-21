# ShieldNet

A peer-to-peer, community-governed insurance pool on Stacks. Members deposit STX, file claims, vote on payouts, and collectively manage risk—no centralized authority required.

---

## Overview

**ShieldNet** is a smart contract for a trustless insurance pool, enabling users to:

- Join the pool by depositing STX
- File insurance claims and pay a small anti-spam fee
- Vote on claims using deposit-weighted voting power
- Receive payouts if claims are approved by the community
- Withdraw deposits at any time

The contract is designed for full transparency, historical analytics, and robust community governance.

---

## Features

- **Trustless Insurance:** No central authority; all decisions are made by members.
- **Deposit-Weighted Voting:** Voting power is proportional to each member’s deposit.
- **Spam Protection:** Claim submissions require a small fee.
- **Transparent Records:** Historical deposits and claim data are stored on-chain.
- **Flexible Membership:** Members can join or leave at any time.

---

## How It Works

### Membership

- **Join:** Call `join-pool` with at least 1 STX. You become a member and gain voting rights.
- **Withdraw:** Call `withdraw-funds` to withdraw part or all of your deposit. Leaving the pool removes your voting power.

### Filing Claims

- **File:** Members can file a claim using `file-claim`, specifying an amount (up to 10 STX) and a description. A 0.05 STX fee is required.
- **Voting:** Each claim is open for voting for approximately 1 day (144 blocks). Members vote to approve or reject, weighted by their deposit.

### Voting & Payouts

- **Vote:** Use `vote-on-claim` to cast your vote (approve/reject) on active claims. Each member can vote once per claim.
- **Process:** After the voting period, anyone can call `process-claim` to finalize the outcome. If 70% or more of votes (by deposit) approve, the claimant receives the payout.

---

## Contract Details

| Parameter                  | Value/Description                          |
|----------------------------|--------------------------------------------|
| Minimum Deposit            | 1 STX                                      |
| Maximum Claim Amount       | 10 STX                                     |
| Claim Fee                  | 0.05 STX                                   |
| Voting Period              | 144 blocks (~1 day)                        |
| Approval Threshold         | 70% of votes (by deposit)                  |
| Governance                 | Community voting, deposit-weighted         |

---

## Public Functions

| Function          | Purpose                                                      |
|-------------------|-------------------------------------------------------------|
| `join-pool`       | Join the pool by depositing STX                             |
| `file-claim`      | File a new insurance claim                                  |
| `vote-on-claim`   | Vote to approve or reject a claim                           |
| `withdraw-funds`  | Withdraw part or all of your deposit                        |
| `process-claim`   | Finalize a claim and pay out if approved                    |

---

## Error Codes

| Code   | Meaning                                  |
|--------|------------------------------------------|
| u1     | Deposit below minimum                    |
| u2     | Already a member                         |
| u3     | Not a pool member                        |
| u4     | Claim exceeds maximum amount             |
| u5     | Claim amount must be positive            |
| u6     | Description required                     |
| u7     | Not a pool member (voting)               |
| u8     | Claim not active/voting ended            |
| u9     | Already voted on this claim              |
| u10    | Not a pool member (withdrawal)           |
| u11    | Insufficient funds to withdraw           |
| u12    | Claim not found                          |
| u13    | Vote counts not found                    |
| u14    | Claim not active                         |
| u15    | Voting period not ended                  |
| u16    | Insufficient pool funds for payout       |

---

## Getting Started

1. **Deploy the contract** on the Stacks blockchain.
2. **Join the pool** by calling `join-pool` with at least 1 STX.
3. **File claims** and participate in voting as described above.

---

## Contributing

Contributions are welcome! To contribute:

- Fork this repository
- Open an issue to discuss your proposal
- Submit a pull request with clear, documented changes

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

## Related

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Smart Contracts](https://docs.stacks.co/write-smart-contracts/clarity-language)
- [OpenZeppelin Governance](https://docs.openzeppelin.com/contracts/4.x/governance)

---

## Disclaimer

This contract is experimental and unaudited. Use at your own risk.
