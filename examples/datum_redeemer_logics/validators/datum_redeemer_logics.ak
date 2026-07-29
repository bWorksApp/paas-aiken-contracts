use cardano/transaction.{Transaction}

pub type Datum {
  number: Int,
  string: ByteArray,
}

pub type Redeemer {
  number: Int,
  string: ByteArray,
}

validator datum_redeemer_logics {
  spend(datum: Option<Datum>, redeemer: Redeemer, _utxo: Data, _self: Transaction) {
    when datum is {
      Some(d) -> {
        let is_same_string = redeemer.string == d.string
        let is_same_number = redeemer.number == d.number
        is_same_string && is_same_number
      }
      None -> False
    }
  }
}