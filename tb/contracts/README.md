
# TrustBridge: P2P Trust and Payment Protocol

TrustBridge is a peer-to-peer trust and payment protocol implemented as a smart contract on the Stacks blockchain. It enables users to initiate deals, complete payments, and build trust profiles based on transaction ratings.


## Overview

TrustBridge facilitates trusted transactions between parties by combining payment functionality with a reputation system. Users can initiate deals, complete payments, and rate their counterparties, building a decentralized trust network.

## Features

- Initiate peer-to-peer deals
- Complete payments for deals
- Rate counterparties after transactions
- Build and query trust profiles
- Retrieve deal information

## Smart Contract Functions

### Public Functions

1. `initiate-deal`: Start a new deal with a counterparty
2. `complete-payment`: Fulfill the payment for a deal
3. `rate-counterparty`: Rate the counterparty after a deal
4. `get-trust-profile`: Query the trust profile of an address
5. `get-deal-info`: Retrieve information about a specific deal

### Private Functions

1. `validate-counterparty`: Ensure the counterparty is valid
2. `validate-deal-id`: Verify the deal ID is within valid range

## Data Structures

### Deals Map

Stores information about each deal:

- `deal-id`: Unique identifier for the deal
- `initiator`: Address of the deal initiator
- `counterparty`: Address of the deal counterparty
- `value`: Amount of STX involved in the deal
- `state`: Current state of the deal (e.g., "OPEN", "FULFILLED")
- `timestamp`: Block height when the deal was initiated
- `trust-score`: Rating given by the counterparty

### Trust Profiles Map

Stores trust information for each address:

- `address`: User's principal address
- `cumulative-score`: Total of all ratings received
- `deal-count`: Number of deals completed

## Constants

- `ADMIN`: The contract deployer's address
- `ERR-NOT-AUTHORIZED`: Error for unauthorized actions
- `ERR-ZERO-AMOUNT`: Error for zero-value transactions
- `ERR-SELF-DEAL`: Error for attempting to deal with oneself
- `ERR-DEAL-NOT-EXIST`: Error when a deal doesn't exist
- `ERR-BAD-RATING`: Error for invalid rating values
- `ERR-INVALID-DEAL-ID`: Error for non-existent deal IDs

## Getting Started

To use TrustBridge, you'll need to interact with the Stacks blockchain. Ensure you have:

1. A Stacks wallet (e.g., Hiro Wallet)
2. Some STX tokens for transaction fees and payments
3. Access to a Stacks blockchain node

## Usage

Here's a basic workflow for using TrustBridge:

1. Initiate a deal using `initiate-deal`
2. Complete the payment with `complete-payment`
3. Rate your counterparty using `rate-counterparty`
4. Query trust profiles with `get-trust-profile`
5. Retrieve deal information using `get-deal-info`

## Security Considerations

- Ensure you trust the contract deployer, as they have ADMIN privileges
- Verify all transaction details before signing
- Be cautious when dealing with new or low-rated counterparties

## Contributing

Contributions to TrustBridge are welcome! Please follow these steps:

1. Fork the repository
2. Create a new branch for your feature
3. Commit your changes
4. Push to your fork
5. Submit a pull request
