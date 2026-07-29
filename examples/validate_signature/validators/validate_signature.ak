use cardano/transaction.{Transaction}

pub type Datum {
  owner: ByteArray,
}

validator validate_signature {
  spend(datum: Option<Datum>, _redeemer: Data, _utxo: Data, _self: Transaction) {
    when datum is {
      Some(_) -> True
      None -> False
    }
  }
}
