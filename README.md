# Algorithmic Trust Bonds

A Clarity smart contract implementing trust bonds that decay over time unless actively reaffirmed by the issuer. This enables dynamic, time-based trust relationships on the Stacks blockchain.

## 🎯 Overview

Algorithmic Trust Bonds introduce a novel mechanism for establishing and maintaining trust relationships in decentralized systems. Bonds decay automatically after ~10 hours unless the issuer actively reaffirms their commitment by extending the bond and optionally increasing its value.

## ✨ Features

- **Issue Bonds**: Create new trust bonds with a minimum value of 1 STX
- **Reaffirm Bonds**: Extend bond lifespan and accumulate additional value
- **Revoke Bonds**: Terminate bonds early with issuer authorization
- **Bond Validation**: Read-only functions to check bond status and validity
- **Secure Value Transfer**: STX transfers locked within the contract
- **Authorization Checks**: Only bond issuers can manage their own bonds

## 📋 Contract Functions

### Public Functions

#### `issue-bond (beneficiary: principal, value: uint) → (ok uint) | (err uint)`
Creates a new trust bond between the issuer and beneficiary.

**Parameters:**
- `beneficiary`: Principal who receives the trust bond
- `value`: Initial bond value in microSTX (minimum 1,000,000 = 1 STX)

**Returns:** Bond ID on success, error code on failure

**Example:**
```clarity
(issue-bond 'SP2JXKMH007NPZKYXPMJDQG5JS6PXUTMAABJNYHIA u1000000)
