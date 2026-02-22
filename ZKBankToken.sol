// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ZKBankToken
 * @dev ERC20 token for the ZK Credit Layer Programmable Bank Core
 * @notice This token is used as the primary lending/borrowing asset in the protocol
 */
contract ZKBankToken is ERC20, ERC20Burnable, Ownable {
    uint256 public constant MAX_SUPPLY = 1000000000 * 10**18; // 1 billion tokens

    /**
     * @dev Constructor that initializes the token with name and symbol
     * @param initialOwner The address that will own the contract
     */
    constructor(address initialOwner) 
        ERC20("ZK Credit Bank Token", "ZKBT") 
        Ownable(initialOwner) 
    {
        // Mint initial supply to owner for liquidity provision
        _mint(initialOwner, 100000000 * 10**18); // 100 million initial supply
    }

    /**
     * @dev Mint new tokens (only owner can call)
     * @param to Address to receive the minted tokens
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "ZKBankToken: Max supply exceeded"
        );
        _mint(to, amount);
    }

    /**
     * @dev Override decimals to 18 for consistency
     */
    function decimals() public pure override returns (uint8) {
        return 18;
    }
}
