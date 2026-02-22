/*
 * ZK Credit Score Circuit
 * 
 * Purpose: Prove that a user's credit score meets a minimum threshold
 * without revealing the actual score or personal financial data
 * 
 * Circuit Logic:
 * - Private Inputs: creditScore (actual score), secret (user secret)
 * - Public Inputs: threshold (minimum required score), nullifierHash
 * 
 * Constraints:
 * 1. creditScore >= threshold (user meets credit requirement)
 * 2. nullifierHash = hash(secret, userAddress) (prevents double-spending)
 */

pragma circom 2.0.0;

include "circomlib/poseidon.circom";
include "circomlib/bitify.circom";
include "circomlib/switcher.circom";

/**
 * Main Credit Score Verification Template
 */
template CreditCheck() {
    // Private inputs (not revealed on-chain)
    signal input creditScore;
    signal input secret;
    
    // Public inputs (revealed on-chain)
    signal input threshold;
    signal input nullifierHash;
    signal input userAddress;
    
    // Output signals
    signal output valid;
    
    // Constraint 1: Credit score must meet or exceed threshold
    // We use a comparison to ensure creditScore >= threshold
    component gte = GreaterEqThan(32);
    gte.in[0] <== creditScore;
    gte.in[1] <== threshold;
    
    // Constraint 2: Generate nullifier hash
    // nullifierHash = Poseidon(secret, userAddress)
    component poseidon = Poseidon(2);
    poseidon.inputs[0] <== secret;
    poseidon.inputs[1] <== userAddress;
    
    // Constrain the nullifier hash to match the public input
    nullifierHash === poseidon.out;
    
    // Output: 1 if creditScore >= threshold, 0 otherwise
    valid <== gte.out;
}

/**
 * Template for Credit Score Range Proof
 * Proves credit score is within a valid range without revealing exact value
 */
template CreditScoreRange() {
    // Private inputs
    signal input creditScore;
    signal input secret;
    
    // Public inputs
    signal input minThreshold;
    signal input maxThreshold;
    signal input nullifierHash;
    signal input userAddress;
    
    // Output
    signal output valid;
    
    // Constraint 1: creditScore >= minThreshold
    component gteMin = GreaterEqThan(32);
    gteMin.in[0] <== creditScore;
    gteMin.in[1] <== minThreshold;
    
    // Constraint 2: creditScore <= maxThreshold
    component lteMax = LessEqThan(32);
    lteMax.in[0] <== creditScore;
    lteMax.in[1] <== maxThreshold;
    
    // Constraint 3: Generate nullifier
    component poseidon = Poseidon(2);
    poseidon.inputs[0] <== secret;
    poseidon.inputs[1] <== userAddress;
    nullifierHash === poseidon.out;
    
    // Valid if both constraints pass
    valid <== gteMin.out * lteMax.out;
}

/**
 * Debt-to-Income Ratio Circuit
 * Proves user's debt-to-income ratio is below a threshold
 */
template DebtToIncomeCheck() {
    // Private inputs
    signal input monthlyIncome;
    signal input monthlyDebt;
    signal input secret;
    
    // Public inputs
    signal input maxRatio; // Maximum allowed DTI ratio (e.g., 43%)
    signal input nullifierHash;
    signal input userAddress;
    
    // Output
    signal output valid;
    
    // Calculate DTI ratio: (monthlyDebt / monthlyIncome) * 100
    // We use integer arithmetic with scaling factor
    
    // First, ensure income > 0 (prevent division by zero)
    component isZero = IsZero();
    isZero.in <== monthlyIncome;
    
    // Calculate ratio with scaling (multiply by 100 to get percentage)
    // ratio = (monthlyDebt * 100) / monthlyIncome
    component div = Division(100);
    div.numer <== monthlyDebt * 100;
    div.denom <== monthlyIncome;
    
    // Check if ratio <= maxRatio
    component lte = LessEqThan(32);
    lte.in[0] <== div.out;
    lte.in[1] <== maxRatio;
    
    // Generate nullifier
    component poseidon = Poseidon(2);
    poseidon.inputs[0] <== secret;
    poseidon.inputs[1] <== userAddress;
    nullifierHash === poseidon.out;
    
    // Output valid if all constraints pass
    // Note: isZero.out = 1 if income is zero, we want to reject that case
    valid <== lte.out * (1 - isZero.out);
}

/**
 * Composite Credit Score Circuit
 * Combines multiple factors to prove overall creditworthiness
 */
template CompositeCreditCheck() {
    // Private inputs
    signal input paymentHistory;    // Score based on payment history (0-100)
    signal input creditUtilization; // Score based on credit usage (0-100)
    signal input accountAge;        // Score based on account age (0-100)
    signal input secret;
    
    // Public inputs
    signal input minCompositeScore; // Minimum required composite score
    signal input nullifierHash;
    signal input userAddress;
    
    // Weights for each factor
    signal input weightPayment;
    signal input weightUtilization;
    signal input weightAge;
    
    // Output
    signal output valid;
    
    // Calculate weighted composite score
    // composite = (paymentHistory * weightPayment + creditUtilization * weightUtilization + accountAge * weightAge) / 100
    
    component mult1 = Multiplier2();
    mult1.a <== paymentHistory;
    mult1.b <== weightPayment;
    
    component mult2 = Multiplier2();
    mult2.a <== creditUtilization;
    mult2.b <== weightUtilization;
    
    component mult3 = Multiplier2();
    mult3.a <== accountAge;
    mult3.b <== weightAge;
    
    signal sum;
    sum <-- mult1.out + mult2.out + mult3.out;
    
    // Divide by 100 to get final composite score
    component div = Division(100);
    div.numer <== sum;
    div.denom <== 100;
    
    // Check if composite score >= minimum required
    component gte = GreaterEqThan(32);
    gte.in[0] <== div.out;
    gte.in[1] <== minCompositeScore;
    
    // Generate nullifier
    component poseidon = Poseidon(2);
    poseidon.inputs[0] <== secret;
    poseidon.inputs[1] <== userAddress;
    nullifierHash === poseidon.out;
    
    valid <== gte.out;
}

/**
 * Main component - CreditCheck (used for circuit compilation)
 */
component main {public [threshold, nullifierHash, userAddress]} = CreditCheck();
