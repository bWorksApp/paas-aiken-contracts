use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use cardano/transaction.{Transaction}

pub type Datum {
  owner: VerificationKeyHash,
}

fn is_signed_by_datum_owner(datum: Datum, tx: Transaction) -> Bool {
  list.has(tx.extra_signatories, datum.owner)
}

validator validate_signature {
  spend(datum: Option<Datum>, _redeemer: Data, _utxo: Data, self: Transaction) {
    when datum is {
      Some(d) -> is_signed_by_datum_owner(d, self)
      None -> False
    }
  }
}
