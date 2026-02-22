/*
 * ZK Credit Layer - Deployment Script
 * 
 * This script deploys all contracts in the correct order:
 * 1. ZKBankToken - ERC20 token for lending/borrowing
 * 2. CreditVerifier - ZK-SNARK verifier contract
 * 3. LoanManager - Manages loan lifecycle
 * 4. BankCore - Main banking core
 * 
 * Usage:
 *   npx hardhat run scripts/deploy.js --network localhost
 *   npx hardhat run scripts/deploy.js --network sepolia
 */

const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

// Configuration
const CONFIG = {
    TOKEN_NAME: "ZK Credit Bank Token",
    TOKEN_SYMBOL: "ZKBT",
    INITIAL_SUPPLY: hre.ethers.utils.parseEther("100000000"), // 100M tokens
    ANNUAL_INTEREST_RATE: 500, // 5%
    STANDARD_LTV: 5000, // 50%
    ZK_LTV: 12000, // 120%
    LIQUIDATION_THRESHOLD: 8000, // 80%
};

// Sample verification key (replace with actual key from snarkjs)
const SAMPLE_VK = {
    alpha: [
        "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "0xfedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321"
    ],
    beta: [
        [
            "0x1111111111111111111111111111111111111111111111111111111111111111",
            "0x2222222222222222222222222222222222222222222222222222222222222222"
        ],
        [
            "0x3333333333333333333333333333333333333333333333333333333333333333",
            "0x4444444444444444444444444444444444444444444444444444444444444444"
        ]
    ],
    gamma: [
        [
            "0x5555555555555555555555555555555555555555555555555555555555555555",
            "0x6666666666666666666666666666666666666666666666666666666666666666"
        ],
        [
            "0x7777777777777777777777777777777777777777777777777777777777777777",
            "0x8888888888888888888888888888888888888888888888888888888888888888"
        ]
    ],
    delta: [
        [
            "0x9999999999999999999999999999999999999999999999999999999999999999",
            "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        ],
        [
            "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
            "0xcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
        ]
    ],
    gamma_abc: [
        [
            "0xdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
            "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
        ]
    ]
};

async function main() {
    console.log("\n========================================");
    console.log("ZK Credit Layer - Deployment Started");
    console.log("========================================\n");

    const [deployer] = await hre.ethers.getSigners();
    console.log("Deployer address:", deployer.address);
    console.log("Deployer balance:", (await deployer.getBalance()).toString());
    console.log("");

    // Get network info
    const networkName = hre.network.name;
    const chainId = (await hre.ethers.provider.getNetwork()).chainId;
    console.log(`Deploying to network: ${networkName} (Chain ID: ${chainId})`);
    console.log("");

    // ========================================
    // Step 1: Deploy ZKBankToken
    // ========================================
    console.log("Step 1: Deploying ZKBankToken...");
    const ZKBankToken = await hre.ethers.getContractFactory("ZKBankToken");
    const token = await ZKBankToken.deploy(deployer.address);
    await token.deployed();
    console.log("✅ ZKBankToken deployed at:", token.address);

    // ========================================
    // Step 2: Deploy CreditVerifier
    // ========================================
    console.log("\nStep 2: Deploying CreditVerifier...");
    const CreditVerifier = await hre.ethers.getContractFactory("CreditVerifier");
    const verifier = await CreditVerifier.deploy(
        SAMPLE_VK.alpha,
        SAMPLE_VK.beta,
        SAMPLE_VK.gamma,
        SAMPLE_VK.delta,
        SAMPLE_VK.gamma_abc
    );
    await verifier.deployed();
    console.log("✅ CreditVerifier deployed at:", verifier.address);

    // ========================================
    // Step 3: Deploy LoanManager
    // ========================================
    console.log("\nStep 3: Deploying LoanManager...");
    const LoanManager = await hre.ethers.getContractFactory("LoanManager");
    const loanManager = await LoanManager.deploy();
    await loanManager.deployed();
    console.log("✅ LoanManager deployed at:", loanManager.address);

    // ========================================
    // Step 4: Deploy BankCore
    // ========================================
    console.log("\nStep 4: Deploying BankCore...");
    const BankCore = await hre.ethers.getContractFactory("BankCore");
    const bankCore = await BankCore.deploy(
        token.address,
        loanManager.address,
        deployer.address
    );
    await bankCore.deployed();
    console.log("✅ BankCore deployed at:", bankCore.address);

    // ========================================
    // Step 5: Configure Token
    // ========================================
    console.log("\nStep 5: Configuring token...");
    
    // Transfer some tokens to BankCore for liquidity
    const liquidityAmount = hre.ethers.utils.parseEther("50000000"); // 50M tokens
    await token.transfer(bankCore.address, liquidityAmount);
    console.log(`✅ Transferred ${hre.ethers.utils.formatEther(liquidityAmount)} ZKBT to BankCore`);

    // ========================================
    // Step 6: Save Deployment Info
    // ========================================
    console.log("\nStep 6: Saving deployment information...");
    
    const deploymentInfo = {
        network: networkName,
        chainId: chainId.toString(),
        deployer: deployer.address,
        timestamp: new Date().toISOString(),
        contracts: {
            ZKBankToken: {
                address: token.address,
                abi: ZKBankToken.interface.format()
            },
            CreditVerifier: {
                address: verifier.address,
                abi: CreditVerifier.interface.format()
            },
            LoanManager: {
                address: loanManager.address,
                abi: LoanManager.interface.format()
            },
            BankCore: {
                address: bankCore.address,
                abi: BankCore.interface.format()
            }
        },
        config: CONFIG
    };

    // Save to JSON file
    const deploymentPath = path.join(__dirname, "../deployments");
    if (!fs.existsSync(deploymentPath)) {
        fs.mkdirSync(deploymentPath, { recursive: true });
    }
    
    const fileName = `${networkName}-${Date.now()}.json`;
    fs.writeFileSync(
        path.join(deploymentPath, fileName),
        JSON.stringify(deploymentInfo, null, 2)
    );
    console.log(`✅ Deployment info saved to: deployments/${fileName}`);

    // ========================================
    // Summary
    // ========================================
    console.log("\n========================================");
    console.log("Deployment Complete!");
    console.log("========================================\n");
    console.log("Contract Addresses:");
    console.log("-------------------");
    console.log(`ZKBankToken:   ${token.address}`);
    console.log(`CreditVerifier: ${verifier.address}`);
    console.log(`LoanManager:    ${loanManager.address}`);
    console.log(`BankCore:       ${bankCore.address}`);
    console.log("");
    console.log("Next Steps:");
    console.log("-----------");
    console.log("1. Verify contracts on Etherscan (if on testnet/mainnet)");
    console.log("2. Update frontend configuration with these addresses");
    console.log("3. Generate ZK proving keys and verification keys");
    console.log("4. Run tests: npx hardhat test");
    console.log("");

    // Return deployment info for programmatic use
    return deploymentInfo;
}

// Execute deployment
main()
    .then((info) => {
        process.exit(0);
    })
    .catch((error) => {
        console.error("\n❌ Deployment failed!");
        console.error(error);
        process.exit(1);
    });
