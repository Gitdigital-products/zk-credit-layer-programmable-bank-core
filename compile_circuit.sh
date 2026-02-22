#!/bin/bash
#
# ZK Circuit Compilation Script
# 
# Compiles the credit_score.circom circuit and generates:
# - R1CS (Rank-1 Constraint System) file
# - WASM (WebAssembly) for proof generation
# - Symbols file for debugging
# - ZKey (Proving & Verification keys)
#
# Prerequisites:
#   npm install -g circom
#   npm install snarkjs
#

set -e

# Configuration
CIRCUIT_NAME="credit_score"
CIRCUIT_DIR="./circuits"
BUILD_DIR="./build"
PTAU_NAME="powersOfTau28_hez_final"
PTAU_DIR="./ptau"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "========================================"
echo "ZK Circuit Compilation Script"
echo "========================================"
echo ""

# Create directories if they don't exist
mkdir -p $BUILD_DIR
mkdir -p $PTAU_DIR

# Step 1: Compile the circuit
echo -e "${YELLOW}Step 1: Compiling circuit...${NC}"
echo "Command: circom $CIRCUIT_DIR/${CIRCUIT_NAME}.circom --r1cs --wasm --sym -o $BUILD_DIR"
circom $CIRCUIT_DIR/${CIRCUIT_NAME}.circom --r1cs --wasm --sym -o $BUILD_DIR

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Circuit compiled successfully${NC}"
    ls -la $BUILD_DIR/
else
    echo -e "${RED}✗ Circuit compilation failed${NC}"
    exit 1
fi

echo ""

# Step 2: Check if we need to download or generate PTAU
PTAU_FILE="$PTAU_DIR/${PTAU_NAME}_final.ptau"

if [ -f "$PTAU_FILE" ]; then
    echo -e "${YELLOW}Step 2: Using existing PTAU file${NC}"
    echo "File: $PTAU_FILE"
else
    echo -e "${YELLOW}Step 2: Downloading PTAU file...${NC}"
    # Download precompiled PTAU
    # Note: In production, generate your own for security
    echo "Downloading ${PTAU_NAME}_final.ptau..."
    # Placeholder - in production, use trusted setup
    echo "Note: For production, run your own trusted setup ceremony"
fi

echo ""

# Step 3: Setup ZKey (Phase 2)
echo -e "${YELLOW}Step 3: Setting up ZKey...${NC}"

# Generate the .zkey file
echo "Command: snarkjs groth16 setup $BUILD_DIR/${CIRCUIT_NAME}.r1cs $PTAU_FILE $BUILD_DIR/${CIRCUIT_NAME}_0000.zkey"

if [ -f "$PTAU_FILE" ]; then
    snarkjs groth16 setup $BUILD_DIR/${CIRCUIT_NAME}.r1cs $PTAU_FILE $BUILD_DIR/${CIRCUIT_NAME}_0000.zkey
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ ZKey generated successfully${NC}"
    else
        echo -e "${RED}✗ ZKey generation failed${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ PTAU file not found. Please download or generate PTAU first.${NC}"
    exit 1
fi

echo ""

# Step 4: Contribute to the ceremony (optional)
echo -e "${YELLOW}Step 4: Contributing to trusted setup (optional)...${NC}"
echo "Command: snarkjs zkey contribute $BUILD_DIR/${CIRCUIT_NAME}_0000.zkey $BUILD_DIR/${CIRCUIT_NAME}_0001.zkey --name='Contributor 1' -v"

read -p "Would you like to contribute to the trusted setup? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    snarkjs zkey contribute $BUILD_DIR/${CIRCUIT_NAME}_0000.zkey $BUILD_DIR/${CIRCUIT_NAME}_0001.zkey --name="Contributor 1" -v
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Contribution successful${NC}"
        ZKEY_FILE="$BUILD_DIR/${CIRCUIT_NAME}_0001.zkey"
    else
        echo -e "${RED}✗ Contribution failed${NC}"
        exit 1
    fi
else
    ZKEY_FILE="$BUILD_DIR/${CIRCUIT_NAME}_0000.zkey"
fi

echo ""

# Step 5: Export verification key
echo -e "${YELLOW}Step 5: Exporting verification key...${NC}"
echo "Command: snarkjs zkey export verificationkey $ZKEY_FILE $BUILD_DIR/verification_key.json"

snarkjs zkey export verificationkey $ZKEY_FILE $BUILD_DIR/verification_key.json

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Verification key exported${NC}"
    cat $BUILD_DIR/verification_key.json
else
    echo -e "${RED}✗ Verification key export failed${NC}"
    exit 1
fi

echo ""

# Step 6: Generate Solidity verifier
echo -e "${YELLOW}Step 6: Generating Solidity verifier contract...${NC}"
echo "Command: snarkjs zkey export solidityverifier $ZKEY_FILE $BUILD_DIR/Verifier.sol"

snarkjs zkey export solidityverifier $ZKEY_FILE $BUILD_DIR/Verifier.sol

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Solidity verifier generated${NC}"
    ls -la $BUILD_DIR/Verifier.sol
else
    echo -e "${RED}✗ Solidity verifier generation failed${NC}"
    exit 1
fi

echo ""

# Summary
echo "========================================"
echo -e "${GREEN}Circuit Compilation Complete!${NC}"
echo "========================================"
echo ""
echo "Generated files:"
echo "  - $BUILD_DIR/${CIRCUIT_NAME}.r1cs (Circuit constraints)"
echo "  - $BUILD_DIR/${CIRCUIT_NAME}_js/ (WASM for proof generation)"
echo "  - $BUILD_DIR/${CIRCUIT_NAME}_0000.zkey (Proving key)"
echo "  - $BUILD_DIR/verification_key.json (Verification key)"
echo "  - $BUILD_DIR/Verifier.sol (Solidity verifier)"
echo ""
echo "Next steps:"
echo "  1. Deploy the Verifier.sol contract"
echo "  2. Use the verification key in your dApp"
echo "  3. Generate proofs client-side using the WASM"
echo ""
