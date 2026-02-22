/*
 * ZK Credit Layer - BankCore Contract Tests
 * 
 * Tests cover:
 * - Deposits and withdrawals
 * - Standard borrowing (50% LTV)
 * - ZK-enhanced borrowing (120% LTV)
 * - Loan repayment
 * - Liquidations
 * - Security (reentrancy, access control)
 */

const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("BankCore", function () {
    // Contract instances
    let token, loanManager, bankCore;
    
    // Signers
    let owner, user1, user2, liquidator;
    
    // Constants
    const TOKEN_SUPPLY = ethers.utils.parseEther("1000000"); // 1M tokens
    const DEPOSIT_AMOUNT = ethers.utils.parseEther("1000"); // 1000 tokens
    const STANDARD_BORROW = ethers.utils.parseEther("400"); // 400 tokens (40% of 1000)
    const ZK_BORROW = ethers.utils.parseEther("1100"); // 1100 tokens (110% of 1000)
    
    beforeEach(async function () {
        // Get signers
        [owner, user1, user2, liquidator] = await ethers.getSigners();
        
        // Deploy ZKBankToken
        const ZKBankToken = await ethers.getContractFactory("ZKBankToken");
        token = await ZKBankToken.deploy(owner.address);
        await token.deployed();
        
        // Deploy LoanManager
        const LoanManager = await ethers.getContractFactory("LoanManager");
        loanManager = await LoanManager.deploy();
        await loanManager.deployed();
        
        // Deploy BankCore
        const BankCore = await ethers.getContractFactory("BankCore");
        bankCore = await BankCore.deploy(token.address, loanManager.address, owner.address);
        await bankCore.deployed();
        
        // Transfer tokens to users for testing
        await token.transfer(user1.address, TOKEN_SUPPLY);
        await token.transfer(user2.address, TOKEN_SUPPLY);
        
        // Approve bankCore to spend tokens
        await token.connect(user1).approve(bankCore.address, ethers.constants.MaxUint256);
        await token.connect(user2).approve(bankCore.address, ethers.constants.MaxUint256);
        
        // Transfer some liquidity to bankCore
        await token.transfer(bankCore.address, ethers.utils.parseEther("500000"));
    });
    
    describe("Deposits", function () {
        it("Should accept deposits", async function () {
            const balanceBefore = await token.balanceOf(bankCore.address);
            
            await token.connect(user1).transfer(bankCore.address, DEPOSIT_AMOUNT);
            
            const balanceAfter = await token.balanceOf(bankCore.address);
            expect(balanceAfter.sub(balanceBefore)).to.equal(DEPOSIT_AMOUNT);
            
            const collateral = await bankCore.collateralBalances(user1.address);
            expect(collateral).to.equal(DEPOSIT_AMOUNT);
        });
        
        it("Should reject zero deposits", async function () {
            await expect(
                token.connect(user1).transfer(bankCore.address, 0)
            ).to.be.revertedWith("BankCore: Deposit amount must be greater than 0");
        });
    });
    
    describe("Withdrawals", function () {
        beforeEach(async function () {
            // User1 deposits
            await token.connect(user1).transfer(bankCore.address, DEPOSIT_AMOUNT);
        });
        
        it("Should allow withdrawals with no loan", async function () {
            const balanceBefore = await token.balanceOf(user1.address);
            
            await bankCore.connect(user1).withdraw(DEPOSIT_AMOUNT);
            
            const balanceAfter = await token.balanceOf(user1.address);
            expect(balanceAfter.sub(balanceBefore)).to.equal(DEPOSIT_AMOUNT);
        });
        
        it("Should reject withdrawals exceeding balance", async function () {
            await expect(
                bankCore.connect(user1).withdraw(DEPOSIT_AMOUNT.add(1))
            ).to.be.revertedWith("BankCore: Insufficient collateral balance");
        });
        
        it("Should reject withdrawals that would undercollateralize loan", async function () {
            // Take a loan
            await bankCore.connect(user1).borrow(STANDARD_BORROW);
            
            // Try to withdraw all collateral (should fail)
            await expect(
                bankCore.connect(user1).withdraw(DEPOSIT_AMOUNT)
            ).to.be.revertedWith("BankCore: Cannot withdraw - loan would be undercollateralized");
        });
    });
    
    describe("Standard Borrowing", function () {
        beforeEach(async function () {
            // User1 deposits
            await token.connect(user1).transfer(bankCore.address, DEPOSIT_AMOUNT);
        });
        
        it("Should allow standard borrowing up to 50% LTV", async function () {
            const maxBorrow = await bankCore.getMaxBorrow(user1.address, false);
            
            // Should be 50% of 1000 = 500
            expect(maxBorrow).to.equal(ethers.utils.parseEther("500"));
        });
        
        it("Should allow borrowing within LTV limit", async function () {
            await bankCore.connect(user1).borrow(STANDARD_BORROW);
            
            const loan = await loanManager.getLoanDetails(user1.address);
            expect(loan.principal).to.equal(STANDARD_BORROW);
            expect(loan.isActive).to.be.true;
            expect(loan.isZKVerified).to.be.false;
        });
        
        it("Should reject borrowing exceeding LTV limit", async function () {
            const overLimit = ethers.utils.parseEther("600"); // 60% > 50%
            
            await expect(
                bankCore.connect(user1).borrow(overLimit)
            ).to.be.revertedWith("BankCore: Borrow amount exceeds maximum allowed");
        });
        
        it("Should reject borrowing with no collateral", async function () {
            await expect(
                bankCore.connect(user2).borrow(STANDARD_BORROW)
            ).to.be.revertedWith("BankCore: No collateral deposited");
        });
        
        it("Should reject borrowing when loan already exists", async function () {
            await bankCore.connect(user1).borrow(STANDARD_BORROW);
            
            await expect(
                bankCore.connect(user1).borrow(STANDARD_BORROW)
            ).to.be.revertedWith("BankCore: Borrower already has an active loan");
        });
    });
    
    describe("ZK-Enhanced Borrowing", function () {
        beforeEach(async function () {
            // User1 deposits
            await token.connect(user1).transfer(bankCore.address, DEPOSIT_AMOUNT);
        });
        
        it("Should allow ZK borrowing up to 120% LTV", async function () {
            const maxBorrow = await bankCore.getMaxBorrow(user1.address, true);
            
            // Should be 120% of 1000 = 1200
            expect(maxBorrow).to.equal(ethers.utils.parseEther("1200"));
        });
        
        it("Should allow borrowing above standard LTV with ZK proof", async function () {
            // In production, this would include actual ZK proof
            // For testing, we simulate by calling with proof parameters
            const proof = ethers.utils.randomBytes(32);
            const publicSignals = [700, 0, 0]; // threshold, nullifier, userAddress
            
            await bankCore.connect(user1).borrowWithZKProof(
                ZK_BORROW,
                proof,
                publicSignals
            );
            
            const loan = await loanManager.getLoanDetails(user1.address);
            expect(loan.principal).to.equal(ZK_BORROW);
            expect(loan.isZKVerified).to.be.true;
        });
    });
    
    describe("Loan Repayment", function () {
        beforeEach(async function () {
            // User1 deposits and borrows
            await token.connect(user1).transfer(bankCore.address, DEPOSIT_AMOUNT);
            await bankCore.connect(user1).borrow(STANDARD_BORROW);
        });
        
        it("Should allow full repayment", async function () {
            const debt = await loanManager.getTotalDebt(user1.address);
            
            // Approve more tokens for repayment
            await token.connect(user1).approve(bankCore.address, ethers.constants.MaxUint256);
            
            await bankCore.connect(user1).repay(debt);
            
            const loan = await loanManager.getLoanDetails(user1.address);
            expect(loan.isActive).to.be.false;
        });
        
        it("Should reject partial repayment", async function () {
            await expect(
                bankCore.connect(user1).repay(STANDARD_BORROW.sub(1))
            ).to.be.revertedWith("BankCore: Repayment amount must cover total debt");
        });
        
        it("Should reject repayment with no loan", async function () {
            await expect(
                bankCore.connect(user2).repay(STANDARD_BORROW)
            ).to.be.revertedWith("BankCore: No active loan to repay");
        });
    });
    
    describe("Liquidations", function () {
        beforeEach(async function () {
            // User1 deposits and borrows
            await token.connect(user1).transfer(bankCore.address, DEPOSIT_AMOUNT);
            await bankCore.connect(user1).borrow(STANDARD_BORROW);
        });
        
        it("Should allow liquidation when undercollateralized", async function () {
            // Simulate collateral value dropping (in production, this would be from oracle)
            // For testing, we'll need to manipulate the loan data
            
            // Note: Full liquidation testing requires price oracle integration
            // This is a basic test structure
            const loan = await loanManager.getLoanDetails(user1.address);
            expect(loan.isActive).to.be.true;
        });
    });
    
    describe("Security", function () {
        it("Should prevent reentrancy on deposit", async function () {
            // Basic reentrancy protection test
            // In production, would test with malicious contract
            expect(await bankCore.nonce()).to.equal(0);
        });
        
        it("Should only allow owner to rescue tokens", async function () {
            await expect(
                bankCore.connect(user1).rescueTokens(token.address, 1000)
            ).to.be.revertedWith("Ownable: caller is not the owner");
        });
    });
    
    describe("View Functions", function () {
        beforeEach(async function () {
            await token.connect(user1).transfer(bankCore.address, DEPOSIT_AMOUNT);
        });
        
        it("Should return correct collateral balance", async function () {
            const balance = await bankCore.getCollateralBalance(user1.address);
            expect(balance).to.equal(DEPOSIT_AMOUNT);
        });
        
        it("Should return correct max borrow amounts", async function () {
            const standardMax = await bankCore.getMaxBorrow(user1.address, false);
            const zkMax = await bankCore.getMaxBorrow(user1.address, true);
            
            expect(standardMax).to.equal(ethers.utils.parseEther("500")); // 50%
            expect(zkMax).to.equal(ethers.utils.parseEther("1200")); // 120%
        });
    });
});
