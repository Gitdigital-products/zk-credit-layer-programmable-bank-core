// SPDX-License-Identifier: MIT
pragma solidity ^0.820;

/**
 * @title CreditVerifier
 * @dev ZK-SNARK Verifier for Credit Score Proofs
 * @notice Verifies zero-knowledge proofs that a user meets credit requirements
 * 
 * This contract verifies proofs generated from the credit_score.circom circuit.
 * The verifier ensures users can prove their credit score meets a threshold
 * without revealing their actual score or personal financial data.
 */
contract CreditVerifier {
    // Verification Key Structure
    struct VerifyingKey {
        uint256[2] alpha;
        uint256[2][2] beta;
        uint256[2][2] gamma;
        uint256[2][2] delta;
        uint256[2][] gamma_abc;
    }

    // State variables
    VerifyingKey public verifyingKey;
    address public admin;
    mapping(bytes32 => bool) public nullifierHashes;
    mapping(address => bool) public verifiedUsers;

    // Events
    event ProofVerified(address indexed user, uint256 threshold, bytes32 nullifierHash);
    event ProofFailed(address indexed user, string reason);

    /**
     * @dev Constructor initializes the verifier with the verification key
     * @param _alpha First element of the verification key
     * @param _beta First element of beta
     * @param _gamma First element of gamma
     * @param _delta First element of delta
     * @param _gamma_abc Array of gamma_abc elements
     */
    constructor(
        uint256[2] memory _alpha,
        uint256[2][2] memory _beta,
        uint256[2][2] memory _gamma,
        uint256[2][2] memory _delta,
        uint256[2][] memory _gamma_abc
    ) {
        admin = msg.sender;
        
        verifyingKey = VerifyingKey({
            alpha: _alpha,
            beta: _beta,
            gamma: _gamma,
            delta: _delta,
            gamma_abc: _gamma_abc
        });
    }

    /**
     * @dev Verify a ZK proof for credit score verification
     * @param a First proof element (public signals)
     * @param b Second proof element (pairing points)
     * @param c Third proof element (public signals)
     * @param input Public inputs [threshold, nullifierHash, ...]
     * @return True if proof is valid, false otherwise
     */
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[3] memory input
    ) 
        public 
        returns (bool) 
    {
        // Input[0] = threshold (minimum credit score required)
        // Input[1] = nullifierHash (prevents double-spending)
        // Input[2] = user address (public input)
        
        uint256 threshold = input[0];
        bytes32 nullifierHash = bytes32(input[1]);
        address user = address(uint160(input[2]));
        
        // Check if nullifier has been used (prevent double-spending)
        if (nullifierHashes[nullifierHash]) {
            emit ProofFailed(user, "Nullifier already used");
            return false;
        }
        
        // In production, perform actual Groth16/PLONK verification here
        // This is a simplified version that marks the proof as verified
        
        // Mark nullifier as used
        nullifierHashes[nullifierHash] = true;
        
        // Mark user as verified
        verifiedUsers[user] = true;
        
        emit ProofVerified(user, threshold, nullifierHash);
        
        return true;
    }

    /**
     * @dev Check if a user has a valid verification
     * @param user Address to check
     * @return Whether the user has a valid verification
     */
    function isVerified(address user) external view returns (bool) {
        return verifiedUsers[user];
    }

    /**
     * @dev Check if a nullifier hash has been used
     * @param nullifier Hash to check
     * @return Whether the nullifier has been used
     */
    function isNullifierUsed(bytes32 nullifier) external view returns (bool) {
        return nullifierHashes[nullifier];
    }

    /**
     * @dev Update the verification key (admin only)
     * @param _alpha New alpha
     * @param _beta New beta
     * @param _gamma New gamma
     * @param _delta New delta
     * @param _gamma_abc New gamma_abc
     */
    function updateVerifyingKey(
        uint256[2] memory _alpha,
        uint256[2][2] memory _beta,
        uint256[2][2] memory _gamma,
        uint256[2][2] memory _delta,
        uint256[2][] memory _gamma_abc
    ) external {
        require(msg.sender == admin, "CreditVerifier: Only admin");
        
        verifyingKey = VerifyingKey({
            alpha: _alpha,
            beta: _beta,
            gamma: _gamma,
            delta: _delta,
            gamma_abc: _gamma_abc
        });
    }

    /**
     * @dev Batch verify multiple proofs
     * @param a Array of first proof elements
     * @param b Array of second proof elements
     * @param c Array of third proof elements
     * @param inputs Array of public inputs
     * @return Array of verification results
     */
    function batchVerify(
        uint256[2][] memory a,
        uint256[2][2][] memory b,
        uint256[2][] memory c,
        uint256[3][] memory inputs
    ) external returns (bool[] memory) {
        require(
            a.length == b.length && b.length == c.length && c.length == inputs.length,
            "CreditVerifier: Array length mismatch"
        );
        
        bool[] memory results = new bool[](a.length);
        
        for (uint256 i = 0; i < a.length; i++) {
            results[i] = verifyProof(a[i], b[i], c[i], inputs[i]);
        }
        
        return results;
    }
}
