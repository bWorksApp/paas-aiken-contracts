# KYC example

This example demonstrates a simple KYC verification smart contract using Aiken.

The validator stores a KYC record with:

- the customer wallet hash
- the authorized reviewer hash
- the verified KYC level
- the expiry timestamp
- a boolean flag indicating whether the record is already verified

It supports two actions:

- Approve: a designated reviewer approves the customer and sets a higher KYC level and expiry
- Revoke: a designated reviewer revokes an existing verification

## Build

```sh
aiken check
```
