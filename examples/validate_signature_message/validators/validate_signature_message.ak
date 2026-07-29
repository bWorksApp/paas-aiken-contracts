use cardano/address.{Address}
use cardano/transaction.{Transaction}

pub type Datum {
  owner: Address,
  dmessage: ByteArray,
}

pub type Redeemer {
  rmessage: ByteArray,
}

validator validate_signature_message {
  spend(datum: Option<Datum>, redeemer: Redeemer, _utxo: Data, _self: Transaction) {
    when datum is {
      Some(d) -> {
        let is_validated_string = redeemer.rmessage == d.dmessage
        let is_validated_signature = True
        is_validated_string && is_validated_signature
      }
      None -> False
    }
  }
}
