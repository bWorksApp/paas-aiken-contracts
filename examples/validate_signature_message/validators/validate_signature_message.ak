use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use cardano/transaction.{Transaction}

pub type Datum {
  owner: VerificationKeyHash,
  dmessage: ByteArray,
}

pub type Redeemer {
  rmessage: ByteArray,
}

fn is_signed_by_datum_owner(datum: Datum, tx: Transaction) -> Bool {
  list.has(tx.extra_signatories, datum.owner)
}

validator validate_signature_message {
  spend(datum: Option<Datum>, redeemer: Redeemer, _utxo: Data, self: Transaction) {
    when datum is {
      Some(d) -> {
        let is_validated_string = redeemer.rmessage == d.dmessage
        let is_validated_signature = is_signed_by_datum_owner(d, self)
        is_validated_string && is_validated_signature
      }
      None -> False
    }
  }
}
