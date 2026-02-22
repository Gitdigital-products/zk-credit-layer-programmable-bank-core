// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./ZKBankToken.sol";
import "./LoanManager.sol";

/**
 * @title BankCore
 * @dev Main core banking contract for the ZK Credit Layer Protocol
 * @notice Handles deposits, withdrawals, borrowing (with optional ZK verification), and repayments
 */
contract BankCore is ReentrancyGuard, Ownable {
    using Math for uint256;

    // Constants
    uint256 public constant STANDARD_LOAN_TO_VALUE = 5000; // 50% LTV for standard loans
    uint256 public constant ZK_LOAN_TO_VALUE = 12000; // 120% LTV for ZK-verified loans
    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant LIQUIDATION_THRESHOLD = 8000; // 80% LTV triggers liquidation

    // State variables
    ZKBankToken public immutable token;
    LoanManager public loanManager;
    
    // User collateral balances
 uint256) public collateralBalances;
    
    // Liquidity pool
    uint256 public total    mapping(address =>Liquidity;
    uint256 public totalDeposits;

    // Events
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount, bool isZKVerified);
    event Repaid(address indexed user, uint256 amount);
    event Liquidated(address indexed liquidator, address indexed borrower, uint256 reward);
    event ZKVerificationFailed(address indexed user, string reason);

    /**
     * @dev Constructor initializes the BankCore with required contracts
     * @param _token Address of the ZKBankToken contract
     * @param _loanManager Address of the LoanManager contract
     * @param initialOwner Address that will own the contract
     */
    constructor(
        address _token,
        address _loanManager,
        address initialOwner
    ) Ownable(initialOwner) {
        require(_token != address(0), "BankCore: Invalid token address");
        require(_loanManager != address(0), "BankCore: Invalid loanManager address");
        
        token = ZKBankToken(_token);
        loanManager = LoanManager(_loanManager);
        
        // Set BankCore address in LoanManager
        loanManager.setBankCore(address(this));
    }

    /**
     * @dev Deposit collateral (ETH or tokens) into the protocol
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "BankCore: Deposit amount must be greater than 0");
        
        // Transfer tokens from user to contract
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "BankCore: Token transfer failed"
        );
        
        collateralBalances[msg.sender] += amount;
        totalDeposits += amount;
        totalLiquidity += amount;
        
        emit Deposited(msg.sender, amount);
    }

    /**
     * @dev Withdraw collateral (if no active loan)
     */
    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "BankCore: Withdraw amount must be greater than 0");
        require(
            collateralBalances[msg.sender] >= amount,
            "BankCore: Insufficient collateral balance"
        );
        
        // Check if user has an active loan
        if (loanManager.hasActiveLoan(msg.sender)) {
            // Calculate available withdrawal amount
            uint256 loanPrincipal = loanManager.getLoanDetails(msg.sender).principal;
            bool isZKVerified = loanManager.getLoanDetails(msg.sender).isZKVerified;
            uint256 maxLTV = isZKVerified ? ZK_LOAN_TO_VALUE : STANDARD_LOAN_TO_VALUE;
            
            // Calculate minimum collateral required
            uint256 minCollateral = (loanPrincipal * BASIS_POINTS) / maxLTV;
            uint256 availableWithdrawal = collateralBalances[msg.sender] - minCollateral;
            
            require(
                amount <= availableWithdrawal,
                "BankCore: Cannot withdraw - loan would be undercollateralized"
            );
        }
        
        collateralBalances[msg.sender] -= amount;
        totalDeposits -= amount;
        totalLiquidity -= amount;
        
        require(
            token.transfer(msg.sender, amount),
            "BankCore: Token transfer failed"
        );
        
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @dev Standard borrow (up to 50% of collateral)
     * @param amount Amount to borrow
     */
    function borrow(uint256 amount) external nonReentrant {
        _borrow(amount, false, bytes(""));
    }

    /**
     * @dev Borrow with ZK verification (up to 120% of collateral)
     * @param amount Amount to borrow
     * @param proof ZK proof data
     * @param publicSignals Public signals from ZK circuit
     */
    function borrowWithZKProof(
        uint256 amount,
        bytes calldata proof,
        uint256[] calldata publicSignals
    ) external nonReentrant {
        // Verify ZK proof (implementation depends on specific verifier)
        // For now, we accept the proof and signals as parameters
        // In production, this would call the CreditVerifier contract
        
        _borrow(amount, true, proof);
    }

    /**
     * @dev Internal borrow function
     * @param amount Amount to borrow
     * @param isZKVerified Whether to use ZK verification for higher LTV
     * @param proof ZK proof data (for verification)
     */
    function _borrow(uint256 amount, bool isZKVerified, bytes memory proof) 
        internal 
    {
        require(amount > 0, "BankCore: Borrow amount must be greater than 0");
        require(
            collateralBalances[msg.sender] > 0,
            "BankCore: No collateral deposited"
        );
        
        // Check if user already has a loan
        if (loanManager.hasActiveLoan(msg.sender)) {
            revert("BankCore: Borrower already has an active loan");
        }
        
        // Determine max borrow based on verification status
        uint256 maxLTV = isZKVerified ? ZK_LOAN_TO_VALUE : STANDARD_LOAN_TO_VALUE;
        uint256 maxBorrow = (collateralBalances[msg.sender] * maxLTV) / BASIS_POINTS;
        
        require(
            amount <= maxBorrow,
            "BankCore: Borrow amount exceeds maximum allowed"
        );
        
        require(
            amount <= totalLiquidity,
            "BankCore: Insufficient liquidity in pool"
        );
        
        // Create loan in LoanManager
        loanManager.createLoan(
            msg.sender,
            amount,
            collateralBalances[msg.sender],
            isZKVerified
        );
        
        // Update liquidity
        totalLiquidity -= amount;
        
        // Transfer borrowed tokens to user
        require(
            token.transfer(msg.sender, amount),
            "BankCore: Token transfer failed"
        );
        
        emit Borrowed(msg.sender, amount, isZKVerified);
    }

    /**
     * @dev Repay loan and unlock collateral
     * @param amount Amount to repay
     */
    function repay(uint256 amount) external nonReentrant {
        require(amount > 0, "BankCore: Repay amount must be greater than 0");
        require(
            loanManager.hasActiveLoan(msg.sender),
            "BankCore: No active loan to repay"
        );
        
        // Calculate total debt
        uint256 totalDebt = loanManager.getTotalDebt(msg.sender);
        
        require(
            amount >= totalDebt,
            "BankCore: Repayment amount must cover total debt"
        );
        
        // Transfer repayment tokens
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "BankCore: Token transfer failed"
        );
        
        // Calculate excess (if any) to return to user
        uint256 excess = amount - totalDebt;
        
        // Close the loan
        loanManager.closeLoan(msg.sender);
        
        // Update liquidity
        uint256 principal = loanManager.getLoanDetails(msg.sender).principal;
        totalLiquidity += principal;
        
        // Return excess to user if any
        if (excess > 0) {
            require(
                token.transfer(msg.sender, excess),
                "BankCore: Excess return failed"
            );
        }
        
        emit Repaid(msg.sender, amount);
    }

    /**
     * @dev Liquidate an undercollateralized loan
     * @param borrower Address of the borrower to liquidate
     */
    function liquidate(address borrower) external nonReentrant {
        require(
            loanManager.hasActiveLoan(borrower),
            "BankCore: No active loan to liquidate"
        );
        
        LoanManager.Loan memory loan = loanManager.getLoanDetails(borrower);
        
        // Calculate current LTV
        uint256 currentLTV = (loan.principal * BASIS_POINTS) / loan.collateral;
        
        require(
            currentLTV > LIQUIDATION_THRESHOLD,
            "BankCore: Loan is not undercollateralized"
        );
        
        // Calculate liquidation reward (10% of collateral)
        uint256 reward = (loan.collateral * 1000) / BASIS_POINTS;
        
        // Close the loan
        loanManager.closeLoan(borrower);
        
        // Transfer collateral to liquidator
        require(
            token.transfer(msg.sender, reward),
            "BankCore: Liquidation reward transfer failed"
        );
        
        // Burn the rest or send to protocol
        uint256 remaining = loan.collateral - reward;
        
        emit Liquidated(msg.sender, borrower, reward);
    }

    /**
     * @dev Get user's collateral balance
     * @param user Address to query
     * @return Collateral balance
     */
    function getCollateralBalance(address user) external view returns (uint256) {
        return collateralBalances[user];
    }

    /**
     * @dev Get maximum borrow amount for a user
     * @param user Address to query
     * @param isZKVerified Whether to calculate with ZK LTV
     * @return Maximum borrowable amount
     */
    function getMaxBorrow(address user, bool isZKVerified) 
        external 
        view 
        returns (uint256) 
    {
        uint256 maxLTV = isZKVerified ? ZK_LOAN_TO_VALUE : STANDARD_LOAN_TO_VALUE;
        return (collateralBalances[user] * maxLTV) / BASIS_POINTS;
    }

    /**
     * @dev Emergency function to rescue tokens
     * @param tokenAddress Address of token to rescue
     * @param amount Amount to rescue
     */
    function rescueTokens(address tokenAddress, uint256 amount) 
        external 
        onlyOwner 
    {
        require(tokenAddress != address(0), "BankCore: Invalid token address");
        require(amount > 0, "BankCore: Amount must be greater than 0");
        
        // Don't allow rescuing the protocol's own token
        require(
            tokenAddress != address(token),
            "BankCore: Cannot rescue protocol token"
        );
        
        require(
            IERC20(tokenAddress).transfer(owner(), amount),
            "BankCore: Token rescue failed"
        );
    }
}
