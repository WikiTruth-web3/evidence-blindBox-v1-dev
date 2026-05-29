# Evidence Market - Contract Testing Suite

This directory contains the unit tests for the **Evidence Market** smart contracts.

## Project Overview

**Evidence Market** is a decentralized whistleblower platform that transforms sensitive investigative evidence into tradeable digital assets. Built on top of **Oasis Sapphire** (a EVM-compatible privacy public chain with TEE-enabled confidential execution), the platform enables whistleblowers to monetize evidence anonymously while protecting their identity.

The local test version in `contracts-eth` is optimized for rapid testing on **Hardhat** without Sapphire-specific TEE and cryptographic library dependencies, simulating the exact same state machine and flow.

---

## Smart Contract Architecture

The test suite covers the following core smart contracts:

1. **`BlindBox` (Core Asset)**:
   - Manages the creation, status lifecycle (`Storing`, `Selling`, `Auctioning`, `Paid`, `Refunding`, `Delaying`, `Published`, `Blacklisted`), and metadata of the evidence blind boxes.

2. **`Exchange` (Trading Engine)**:
   - Handles trade operations including listing for flat-price sale (`sell`) or auction (`auction`), making purchases (`buy` / `bid`), cancelling bids, request/agree/refuse refund, and completing orders.

3. **`FundManager` (Escrow & Reward Distribution)**:
   - Manages payments and user balances in multiple ERC20 tokens.
   - Distributes payouts to minters and service fees to `DAO_TREASURY` once orders are completed.
   - Converts helper rewards to the project's native `settlementToken` using a price oracle, while routing equivalent accepted tokens to the DAO treasury.

4. **`UserManager` (Identity Privacy)**:
   - Maps wallet addresses to pseudo-anonymous, random `bytes32` User IDs to prevent transaction tracing via event logs.

5. **`MockPriceOracle` (Oracles)**:
   - A mock oracle used in the Hardhat testing environment to set exchange rates between accepted payment tokens and the project's settlement token.

---

## Key Game-Theoretic Design Under Test

- **Refund Deterrence (Publish-on-Refund)**:
  If a buyer files a refund request (state becomes `Refunding`), the decryption key for the box is immediately made public. This prevents malicious buyers from "free-riding" on the confidential data and requesting their money back, as the exclusivity of the evidence evaporates upon refund initiation.
- **Auto-Escrow Settlement on Expiry**:
  In auction mode, if the bid refund period passes after the auction ends, any refund attempt is automatically blocked, and funds are forced to settle to the Minter.
- **Oracle-Based Payout Conversion**:
  Helper rewards are converted into the settlement token at Oracle exchange rates, and the corresponding amount of accepted payment tokens is sent to the DAO Treasury along with platform fees.

---

## How to Run the Tests

To run the unit tests in your local environment, follow these steps:

1. **Install dependencies**:
   ```bash
   pnpm install
   # or
   npm install
   ```

2. **Compile the smart contracts**:
   ```bash
   npx hardhat compile
   ```

3. **Run the test suite**:
   ```bash
   npx hardhat test
   ```
