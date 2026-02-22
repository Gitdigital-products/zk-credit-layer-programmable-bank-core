# We start with the foundation: the JSON Schema. This is your constitutional law. Every badge must pass this or it does not exist.

Create:

/schemas/badge.schema.json

Here’s the full production-ready schema:

{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Badge Authority Schema",
  "description": "Canonical schema for all Badge Authority credentials",
  "type": "object",
  "required": [
    "badge_id",
    "category",
    "family",
    "name",
    "description",
    "version",
    "issued_by",
    "created_at",
    "requirements",
    "revocable"
  ],
  "properties": {
    "badge_id": {
      "type": "string",
      "pattern": "^[a-z]+\\.[a-z]+\\.[a-z0-9._]+$"
    },
    "category": {
      "type": "string",
      "enum": ["loan", "grant", "governance", "identity", "compliance"]
    },
    "family": {
      "type": "string",
      "minLength": 2
    },
    "name": {
      "type": "string",
      "minLength": 3
    },
    "description": {
      "type": "string",
      "minLength": 10
    },
    "version": {
      "type": "string",
      "pattern": "^\\d+\\.\\d+\\.\\d+$"
    },
    "issued_by": {
      "type": "string",
      "minLength": 2
    },
    "created_at": {
      "type": "string",
      "format": "date-time"
    },
    "requirements": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "minItems": 1
    },
    "revocable": {
      "type": "boolean"
    },
    "revocation_reason": {
      "type": ["string", "null"]
    }
  },
  "additionalProperties": false
}

This does several important things:

– Enforces semantic versioning
– Prevents malformed badge IDs
– Locks required fields
– Blocks random undocumented fields
– Makes CI validation trivial

Now layer two: Smart contract interface.

We don’t want NFT fluff. We want attestations. Lean. Institutional.

Create:

/contracts/IBadgeRegistry.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBadgeRegistry {

    event BadgeIssued(
        bytes32 indexed badgeHash,
        address indexed recipient,
        string badgeId,
        uint256 timestamp
    );

    event BadgeRevoked(
        bytes32 indexed badgeHash,
        address indexed recipient,
        uint256 timestamp,
        string reason
    );

    function issueBadge(
        address recipient,
        string calldata badgeId,
        bytes32 badgeHash
    ) external;

    function revokeBadge(
        address recipient,
        bytes32 badgeHash,
        string calldata reason
    ) external;

    function isBadgeValid(bytes32 badgeHash) external view returns (bool);
}

How it works:

– Full badge JSON gets hashed off-chain (SHA-256)
– Hash sent on-chain
– Contract stores minimal immutable proof
– Event emitted
– Full JSON stored off-chain

You get cryptographic anchoring without chain bloat.

That’s institutional architecture.

Now layer three: Issuance Service.

Create:

/services/badge-issuer/issuance-engine.ts

import crypto from "crypto";
import Ajv from "ajv";
import badgeSchema from "../../schemas/badge.schema.json";

const ajv = new Ajv({ allErrors: true });
const validate = ajv.compile(badgeSchema);

export function validateBadge(badge: any) {
  const valid = validate(badge);
  if (!valid) {
    throw new Error(JSON.stringify(validate.errors));
  }
  return true;
}

export function generateBadgeHash(badge: any): string {
  const canonical = JSON.stringify(badge);
  return crypto.createHash("sha256").update(canonical).digest("hex");
}

Then:

webhook-handler.ts

import { validateBadge, generateBadgeHash } from "./issuance-engine";

export async function handleWebhook(event: any) {
  const badge = mapEventToBadge(event);

  validateBadge(badge);

  const hash = generateBadgeHash(badge);

  await issueOnChain(event.recipient, badge.badge_id, hash);

  return { status: "issued", hash };
}

Now your pipeline looks like this:

External system triggers event
↓
Webhook received
↓
Badge constructed
↓
Schema validated
↓
Hash generated
↓
On-chain attestation stored
↓
Event logged
↓
Loan pipeline advances

No spreadsheets. No guesswork. No compliance panic attacks.

This is programmable governance.

Now here’s the deeper move.

If you align this with Ethereum Attestation Service standards, you gain interoperability. Other systems can verify your badges without trusting you. That’s the holy grail of institutional trust.

You’re building something that behaves less like a startup feature and more like infrastructure law.

