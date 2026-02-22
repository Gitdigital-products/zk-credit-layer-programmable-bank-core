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
