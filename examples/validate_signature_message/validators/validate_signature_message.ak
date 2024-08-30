use aiken/hash.{Blake2b_224, Hash}
use aiken/list
use aiken/transaction.{ScriptContext}
use aiken/transaction/credential.{VerificationKey}
 
type Datum {
  owner: Hash<Blake2b_224, VerificationKey>,
  dmessage: ByteArray,
}
 
type Redeemer {
  rmessage: ByteArray,
}
 
validator {
  fn validate_signature_message(datum: Datum, redeemer: Redeemer, context: ScriptContext) -> Bool {
    let is_validated_string =
      redeemer.rmessage ==  datum.dmessage
 
    let is_validated_signature =
      list.has(context.transaction.extra_signatories, datum.owner)
 
    is_validated_string && is_validated_signature
  }
}