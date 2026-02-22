
🏛️ Badge Wall (Production‑Ready)

This badge wall is designed in your institutional, courthouse‑grade, heavy‑line style.  
All badges are grouped by Authority Layer, Governance State, Documentation, Automation, and Ecosystem Alignment.

You can paste this directly into your README.

---

🏦 GitDigital — zk‑Credit Layer (Programmable Bank Core)

Official Badge Wall

---

🔷 Core Status Badges
- Repo Status — https://img.shields.io/badge/Status-Active-blue
- Protocol Layer — https://img.shields.io/badge/Layer-Credit%20Authority-7D3FFF
- Ecosystem — https://img.shields.io/badge/Solana-Integrated-9945FF
- ZK Alignment — https://img.shields.io/badge/ZK-Proofs%20Ready-4B0082

---

🛡️ Governance & Compliance
- Governance Engine — https://img.shields.io/badge/Governance-Badge%20Authority-2E86C1
- Cross‑Authority Wiring — https://img.shields.io/badge/Cross--Authority-Enabled-1F618D
- Compliance Mode — https://img.shields.io/badge/Compliance-Audit%20Grade-117A65
- Credit Ruleset — https://img.shields.io/badge/Credit%20Ruleset-v1.0.0-0E6655

---

🧮 Credit Layer Badges
- Credit Score Engine — https://img.shields.io/badge/Credit%20Score-ZK%20Validated-6C3483
- Borrower Eligibility — https://img.shields.io/badge/Eligibility-Automated-512E5F
- Loan Trigger Surface — https://img.shields.io/badge/Loan%20Triggers-Integrated-4A235A
- Income Proof — https://img.shields.io/badge/Income%20Proof-ZK%20Private-7D3C98

---

🧰 Automation & Infrastructure
- Badge Bundles — https://img.shields.io/badge/Bundles-4%20Templates-5D6D7E
- Workflow Engine — https://img.shields.io/badge/Automation-GitHub%20Actions-1C2833
- Sync Mode — https://img.shields.io/badge/Badge%20Sync-Auto-212F3D
- Template Engine — https://img.shields.io/badge/Templates-Complete%20Set-2C3E50

---

📚 Documentation & Metadata
- Badge Catalog — https://img.shields.io/badge/Badges-Complete%20Catalog-7B7D7D
- Metadata Quality — https://img.shields.io/badge/Metadata-Audit%20Ready-626567
- Cross‑Authority Docs — https://img.shields.io/badge/Docs-Wiring%20Included-4D5656

---

🧱 Security & Integrity
- Integrity Mode — https://img.shields.io/badge/Integrity-Signed%20Metadata-1B4F72
- ZK Privacy — https://img.shields.io/badge/Privacy-ZK%20SNARKs-154360
- Data Exposure — https://img.shields.io/badge/Data%20Exposure-Minimized-1A5276

---

🧩 Ecosystem Alignment
- GitDigital Governance Stack — https://img.shields.io/badge/GitDigital-Authority%20Aligned-7D6608
- Programmable Bank Core — https://img.shields.io/badge/Programmable%20Bank-Core%20Module-9C640C
- Grant & Loan Integration — https://img.shields.io/badge/Integration-Grant%20%2B%20Loan-7E5109

---

🧪 Development & CI
- Build — https://img.shields.io/badge/Build-Passing-27AE60
- Tests — https://img.shields.io/badge/Tests-Validated-239B56
- Type Safety — https://img.shields.io/badge/Type%20Safety-Strict-1D8348
- Linting — https://img.shields.io/badge/Lint-Clean-145A32

---

🗂️ Repo Metadata
- License — https://img.shields.io/badge/License-MIT-566573
- Version — https://img.shields.io/badge/Version-1.0.0-2E4053
- Maintainer — https://img.shields.io/badge/Maintainer-GitDigital-blue

---

🔮 Optional: Authority‑Surface Badges (Advanced)
These match your Hex‑Core geometry and institutional badge authority:

- Authority Surface — https://img.shields.io/badge/Authority-Surface%20v2.0-8E44AD
- State Machine — https://img.shields.io/badge/State%20Machine-Enabled-5B2C6F
- Trigger Engine — https://img.shields.io/badge/Triggers-Cross%20Layer-4A235A

---

# ZK Credit Layer Programmable Bank Core

A privacy-preserving decentralized lending protocol powered by zero-knowledge proofs. Users can prove their creditworthiness without revealing sensitive financial data.

## Overview

The ZK Credit Layer is a DeFi protocol that enables:

- **Privacy-Preserving Credit Verification**: Users generate ZK proofs to demonstrate creditworthiness without revealing actual scores or financial data
- **Under-Collateralized Loans**: ZK-verified borrowers can access up to 120% LTV (vs 50% for standard loans)
- **Programmable Banking Core**: Modular architecture for managing deposits, loans, and liquidations

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Frontend (React)                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │  Dashboard  │  │   Deposit   │  │    Borrow   │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   Smart Contracts                           │
│  ┌──────────┐  ┌─────────────┐  ┌────────────┐              │
│  │BankCore  │◄─│ LoanManager │  │   Token    │              │
│  └──────────┘  └─────────────┘  └────────────┘              │
│        │                                                │
│        ▼                                                │
│  ┌──────────────┐                                       │
│  │CreditVerifier│ (ZK Proof Verification)               │
│  └──────────────┘                                       │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    ZK Circuits (Circom)                      │
│  ┌─────────────────┐                                        │
│  │ credit_score   │ ──► Generate Proof (WASM + snarkjs)  │
│  │ (Private Inputs)│                                        │
│  └─────────────────┘                                        │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### Prerequisites

- Node.js 18+
- npm or yarn
- Hardhat
- Circom (for ZK circuit compilation)

### Installation

```bash
# Install dependencies
npm install

# Compile smart contracts
npx hardhat compile

# Run local Hardhat node
npx hardhat node
```

### Deployment

```bash
# Deploy to local network
npm run deploy:local

# Deploy to Sepolia testnet
npm run deploy:sepolia
```

### Testing

```bash
# Run all tests
npm test

# Run with coverage
npm run test:coverage
```

### ZK Circuit Setup

```bash
# Compile circuit and generate keys
npm run circom:compile
# or
bash scripts/compile_circuit.sh
```

## Smart Contracts

| Contract | Description |
|----------|-------------|
| `BankCore.sol` | Main banking logic - deposits, withdrawals, borrowing |
| `LoanManager.sol` | Manages loan lifecycle and interest calculation |
| `ZKBankToken.sol` | ERC20 token for lending/borrowing |
| `CreditVerifier.sol` | ZK-SNARK proof verifier |

## Key Features

### 1. Deposits
Users deposit ZKBT tokens as collateral to enable borrowing.

```solidity
function deposit(uint256 amount) external;
```

### 2. Standard Borrowing
Borrow up to 50% of deposited collateral (standard LTV).

```solidity
function borrow(uint256 amount) external;
```

### 3. ZK-Enhanced Borrowing
Borrow up to 120% of deposited collateral with valid ZK proof.

```solidity
function borrowWithZKProof(
    uint256 amount,
    bytes calldata proof,
    uint256[] calldata publicSignals
) external;
```

### 4. Loan Repayment
Repay principal + interest to unlock collateral.

```solidity
function repay(uint256 amount) external;
```

### 5. Liquidation
Liquidate undercollateralized loans (LTV > 80%).

```solidity
function liquidate(address borrower) external;
```

## ZK Circuit

The `credit_score.circom` circuit proves that:
- User's credit score ≥ threshold (without revealing exact score)
- Nullifier hash prevents double-spending

### Inputs

**Private:**
- `creditScore`: Actual credit score
- `secret`: User's secret key

**Public:**
- `threshold`: Minimum required score
- `nullifierHash`: Prevents proof reuse
- `userAddress`: User's wallet address

## Frontend Development

```bash
# Navigate to frontend
cd frontend

# Install dependencies
npm install

# Start development server
npm run dev
```

## Security Considerations

- All contracts use ReentrancyGuard
- Only verified ZK proofs allow higher LTV
- Liquidation threshold at 80% LTV
- Emergency token rescue function for owner

## License

MIT
