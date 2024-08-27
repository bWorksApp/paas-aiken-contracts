# validate_signature

Validate the number and string attached into datum and redeemer.
The transaction is validated only if the number and string in datum and redeemer are the same.
datum, redeemer format: [number, string]

## Building

```sh
aiken build
```


To run all test:

```sh
aiken check
```

## Try this contract on dApp with installed wallet

```sh
https://paas.bworks.app/web#/trycontract
```