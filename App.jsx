import { useState, useEffect } from 'react'
import { ethers } from 'ethers'
import './App.css'

// Contract addresses (update after deployment)
const CONTRACT_ADDRESSES = {
  ZKBankToken: "0x0000000000000000000000000000000000000001",
  BankCore: "0x0000000000000000000000000000000000000002",
  LoanManager: "0x0000000000000000000000000000000000000003",
  CreditVerifier: "0x0000000000000000000000000000000000000004"
}

function App() {
  const [account, setAccount] = useState(null)
  const [balance, setBalance] = useState("0")
  const [collateral, setCollateral] = useState("0")
  const [activeTab, setActiveTab] = useState("deposit")
  const [amount, setAmount] = useState("")
  const [isLoading, setIsLoading] = useState(false)
  const [status, setStatus] = useState("")

  // Connect wallet
  const connectWallet = async () => {
    if (typeof window.ethereum !== 'undefined') {
      try {
        const provider = new ethers.BrowserProvider(window.ethereum)
        const accounts = await provider.send("eth_requestAccounts", [])
        setAccount(accounts[0])
        
        // Get balance
        const balance = await provider.getBalance(accounts[0])
        setBalance(ethers.formatEther(balance))
      } catch (error) {
        console.error("Failed to connect wallet:", error)
        setStatus("Failed to connect wallet")
      }
    } else {
      setStatus("Please install MetaMask!")
    }
  }

  // Handle deposit
  const handleDeposit = async () => {
    if (!account || !amount) return
    
    setIsLoading(true)
    setStatus("Depositing...")
    
    try {
      // In production, call the actual contract
      // For demo, simulate delay
      await new Promise(resolve => setTimeout(resolve, 2000))
      
      setCollateral(amount)
      setStatus("Deposit successful!")
      setAmount("")
    } catch (error) {
      setStatus("Deposit failed: " + error.message)
    }
    
    setIsLoading(false)
  }

  // Handle borrow
  const handleBorrow = async () => {
    if (!account || !amount) return
    
    setIsLoading(true)
    setStatus("Processing borrow...")
    
    try {
      // In production, call the actual contract
      await new Promise(resolve => setTimeout(resolve, 2000))
      
      setStatus("Borrow successful!")
      setAmount("")
    } catch (error) {
      setStatus("Borrow failed: " + error.message)
    }
    
    setIsLoading(false)
  }

  // Handle ZK proof generation (mock)
  const handleGenerateProof = async () => {
    setIsLoading(true)
    setStatus("Generating ZK proof...")
    
    try {
      // In production, use snarkjs to generate actual proof
      await new Promise(resolve => setTimeout(resolve, 3000))
      
      setStatus("ZK Proof generated! You can now borrow up to 120% LTV")
    } catch (error) {
      setStatus("Proof generation failed")
    }
    
    setIsLoading(false)
  }

  return (
    <div className="app">
      <header className="header">
        <div className="logo">
          <h1>ZK Credit Layer</h1>
          <span className="badge">Bank Core</span>
        </div>
        
        <div className="wallet-section">
          {account ? (
            <div className="wallet-info">
              <span className="address">
                {account.slice(0, 6)}...{account.slice(-4)}
              </span>
              <span className="balance">{parseFloat(balance).toFixed(4)} ETH</span>
            </div>
          ) : (
            <button className="connect-btn" onClick={connectWallet}>
              Connect Wallet
            </button>
          )}
        </div>
      </header>

      <main className="main">
        <div className="stats-grid">
          <div className="stat-card">
            <h3>Total Deposits</h3>
            <p className="stat-value">$0.00</p>
          </div>
          <div className="stat-card">
            <h3>Your Collateral</h3>
            <p className="stat-value">{collateral || "0.00"} ZKBT</p>
          </div>
          <div className="stat-card">
            <h3>Active Loans</h3>
            <p className="stat-value">0</p>
          </div>
        </div>

        <div className="action-section">
          <div className="tabs">
            <button 
              className={`tab ${activeTab === 'deposit' ? 'active' : ''}`}
              onClick={() => setActiveTab('deposit')}
            >
              Deposit
            </button>
            <button 
              className={`tab ${activeTab === 'borrow' ? 'active' : ''}`}
              onClick={() => setActiveTab('borrow')}
            >
              Borrow
            </button>
            <button 
              className={`tab ${activeTab === 'repay' ? 'active' : ''}`}
              onClick={() => setActiveTab('repay')}
            >
              Repay
            </button>
          </div>

          <div className="tab-content">
            {activeTab === 'deposit' && (
              <div className="action-card">
                <h2>Deposit Collateral</h2>
                <p>Deposit ZKBT tokens to start borrowing</p>
                
                <div className="input-group">
                  <input
                    type="number"
                    placeholder="Amount"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                  />
                  <span className="currency">ZKBT</span>
                </div>
                
                <button 
                  className="action-btn"
                  onClick={handleDeposit}
                  disabled={isLoading || !account}
                >
                  {isLoading ? "Processing..." : "Deposit"}
                </button>
              </div>
            )}

            {activeTab === 'borrow' && (
              <div className="action-card">
                <h2>Borrow Funds</h2>
                <p>Use your collateral to borrow ZKBT tokens</p>
                
                <div className="zk-section">
                  <div className="zk-info">
                    <span className="label">Standard LTV:</span>
                    <span className="value">50%</span>
                  </div>
                  <div className="zk-info highlight">
                    <span className="label">ZK-Verified LTV:</span>
                    <span className="value">120%</span>
                  </div>
                </div>
                
                <button 
                  className="zk-btn"
                  onClick={handleGenerateProof}
                  disabled={isLoading}
                >
                  {isLoading ? "Generating..." : "Generate ZK Proof"}
                </button>
                
                <div className="input-group">
                  <input
                    type="number"
                    placeholder="Amount"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                  />
                  <span className="currency">ZKBT</span>
                </div>
                
                <button 
                  className="action-btn"
                  onClick={handleBorrow}
                  disabled={isLoading || !account}
                >
                  {isLoading ? "Processing..." : "Borrow"}
                </button>
              </div>
            )}

            {activeTab === 'repay' && (
              <div className="action-card">
                <h2>Repay Loan</h2>
                <p>Repay your loan to unlock collateral</p>
                
                <div className="info-box">
                  <p>No active loans</p>
                </div>
                
                <div className="input-group">
                  <input
                    type="number"
                    placeholder="Amount"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                    disabled
                  />
                  <span className="currency">ZKBT</span>
                </div>
                
                <button 
                  className="action-btn"
                  disabled
                >
                  Repay
                </button>
              </div>
            )}
          </div>

          {status && (
            <div className="status-bar">
              {status}
            </div>
          )}
        </div>
      </main>
    </div>
  )
}

export default App
