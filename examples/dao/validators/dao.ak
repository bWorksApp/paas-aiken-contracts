use cardano/transaction.{Transaction}

pub type Datum {
  proposal_id: Int,
  owner: ByteArray,
}

pub type Redeemer {
  vote: Int,
}

fn is_approved(datum: Datum, redeemer: Redeemer, expected_owner: ByteArray, quorum: Int) -> Bool {
  let has_valid_proposal = datum.proposal_id > 0
  let has_enough_votes = redeemer.vote >= quorum
  let matches_owner = datum.owner == expected_owner

  has_valid_proposal && has_enough_votes && matches_owner
}

validator dao(expected_owner: ByteArray, quorum: Int) {
  spend(datum: Option<Datum>, redeemer: Redeemer, _utxo: Data, _self: Transaction) {
    when datum is {
      Some(d) -> is_approved(d, redeemer, expected_owner, quorum)
      None -> False
    }
  }
}

test accepts_when_quorum_is_met() {
  let datum = Datum { proposal_id: 1, owner: "dao" }
  let redeemer = Redeemer { vote: 3 }

  is_approved(datum, redeemer, "dao", 3)
}

test rejects_when_quorum_is_not_met() {
  let datum = Datum { proposal_id: 1, owner: "dao" }
  let redeemer = Redeemer { vote: 2 }

  !is_approved(datum, redeemer, "dao", 3)
}

test rejects_when_owner_is_tampered_with() {
  let datum = Datum { proposal_id: 1, owner: "attacker" }
  let redeemer = Redeemer { vote: 3 }

  !is_approved(datum, redeemer, "dao", 3)
}
