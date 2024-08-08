use aiken/hash.{Blake2b_224, Hash}
use aiken/list
use aiken/transaction.{ScriptContext}
use aiken/transaction/credential.{VerificationKey}

type Datum {
  owner: Hash<Blake2b_224, VerificationKey>,
}


validator {
  fn spend(datum: Datum, _, context: ScriptContext) -> Bool {
   
    let is_validated =
      list.has(context.transaction.extra_signatories, datum.owner)

    is_validated
  }
}
