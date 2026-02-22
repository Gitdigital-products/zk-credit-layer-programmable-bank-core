// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title LoanManager
 * @dev Manages loan lifecycle, interest calculation, and loan state
 * @notice Handles the logic for creating, tracking, and closing loans
 */
contract LoanManager {
    // Constants
    uint256 public constant BASIS_POINTS = 10000; // 1% = 100 basis points
    uint256 public constant ANNUAL_INTEREST_RATE = 500; // 5% annual interest rate

    // State variables
    address public bankCore;
    
    // Loan structure
    struct Loan {
        uint256 principal;        // Original borrow amount
        uint256 collateral;       // Collateral deposited
        uint256 interestAccrued;  // Accumulated interest
        uint256 startTime;        // When loan was created
        bool isActive;            // Whether loan is currently active
        bool isZKVerified;        // Whether loan was created with ZK proof
    }

    // Mapping of user address to their loan
    mapping(address => Loan) public loans;

    // Events
    event LoanCreated(
        address indexed borrower,
        uint256 principal,
        uint256 collateral,
        bool isZKVerified
    );
    event LoanRepaid(address indexed borrower, uint256 amount);
    event LoanLiquidated(address indexed borrower, uint256 collateralLost);
    event InterestAccrued(address indexed borrower, uint256 interestAmount);

    // Modifiers
    modifier onlyBankCore() {
        require(msg.sender == bankCore, "LoanManager: Only BankCore can call");
        _;
    }

    modifier loanExists(address borrower) {
        require(loans[borrower].isActive, "LoanManager: No active loan");
        _;
    }

    /**
     * @dev Set the BankCore address (called once after deployment)
     * @param _bankCore Address of the BankCore contract
     */
    function setBankCore(address _bankCore) external {
        require(bankCore == address(0), "LoanManager: BankCore already set");
        require(_bankCore != address(0), "LoanManager: Invalid BankCore address");
        bankCore = _bankCore;
    }

    /**
     * @dev Create a new loan for a borrower
     * @param borrower Address receiving the loan
     * @param principal Amount being borrowed
     * @param collateral Collateral deposited
     * @param isZKVerified Whether the loan was verified with ZK proof
     */
    function createLoan(
        address borrower,
        uint256 principal,
        uint256 collateral,
        bool isZKVerified
    ) external onlyBankCore {
        require(
            !loans[borrower].isActive,
            "LoanManager: Borrower already has an active loan"
        );

        loans[borrower] = Loan({
            principal: principal,
            collateral: collateral,
            interestAccrued: 0,
            startTime: block.timestamp,
            isActive: true,
            isZKVerified: isZKVerified
        });

        emit LoanCreated(borrower, principal, collateral, isZKVerified);
    }

    /**
     * @dev Calculate and accrue interest for a loan
     * @param borrower Address of the borrower
     * @return accruedInterest The amount of interest accrued
     */
    function calculateInterest(address borrower) 
        external 
        view 
        loanExists(borrower) 
        returns (uint256) 
    {
        Loan memory loan = loans[borrower];
        uint256 timeElapsed = block.timestamp - loan.startTime;
        
        // Calculate interest: principal * rate * time / (365 days * BASIS_POINTS)
        uint256 interest = (loan.principal * ANNUAL_INTEREST_RATE * timeElapsed) / 
                          (365 days * BASIS_POINTS);
        
        return interest;
    }

    /**
     * @dev Accrue interest for a borrower (called by BankCore)
     * @param borrower Address of the borrower
     */
    function accrueInterest(address borrower) 
        external 
        onlyBankCore 
        loanExists(borrower) 
    {
        Loan storage loan = loans[borrower];
        uint256 timeElapsed = block.timestamp - loan.startTime;
        
        // Calculate interest
        uint256 interest = (loan.principal * ANNUAL_INTEREST_RATE * timeElapsed) / 
                          (365 days * BASIS_POINTS);
        
        // Only update if there's new interest
        uint256 newInterest = interest - loan.interestAccrued;
        if (newInterest > 0) {
            loan.interestAccrued = interest;
            emit InterestAccrued(borrower, newInterest);
        }
    }

    /**
     * @dev Close a loan after full repayment
     * @param borrower Address of the borrower
     */
    function closeLoan(address borrower) 
        external 
        onlyBankCore 
        loanExists(borrower) 
    {
        Loan storage loan = loans[borrower];
        
        // Accrue final interest
        uint256 timeElapsed = block.timestamp - loan.startTime;
        uint256 totalInterest = (loan.principal * ANNUAL_INTEREST_RATE * timeElapsed) / 
                               (365 days * BASIS_POINTS);
        loan.interestAccrued = totalInterest;
        
        loan.isActive = false;
        
        emit LoanRepaid(borrower, loan.principal + totalInterest);
    }

    /**
     * @dev Get loan details for a borrower
     * @param borrower Address of the borrower
     * @return Loan struct containing all loan details
     */
    function getLoanDetails(address borrower) 
        external 
        view 
        returns (Loan memory) 
    {
        return loans[borrower];
    }

    /**
     * @dev Get total debt (principal + interest) for a borrower
     * @param borrower Address of the borrower
     * @return Total debt amount
     */
    function getTotalDebt(address borrower) 
        external 
        view 
        loanExists(borrower) 
        returns (uint256) 
    {
        Loan memory loan = loans[borrower];
        uint256 timeElapsed = block.timestamp - loan.startTime;
        uint256 totalInterest = (loan.principal * ANNUAL_INTEREST_RATE * timeElapsed) / 
                               (365 days * BASIS_POINTS);
        
        return loan.principal + totalInterest;
    }

    /**
     * @dev Check if a borrower has an active loan
     * @param borrower Address to check
     * @return Whether the borrower has an active loan
     */
    function hasActiveLoan(address borrower) external view returns (bool) {
        return loans[borrower].isActive;
    }
}
