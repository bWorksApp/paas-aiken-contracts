use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use aiken/interval
use cardano/assets.{AssetName, PolicyId, quantity_of}
use cardano/transaction.{InlineDatum, Input, Output, Transaction}

pub type VoteLockDatum {
  proposal_id: Int,
  owner: VerificationKeyHash,
  policy_id: PolicyId,
  asset_name: AssetName,
  locked_amount: Int,
  voting_start: Int,
  voting_end: Int,
}

pub type Redeemer {
  CastVote { vote: Int }
  Unlock
}

fn has_valid_datum(datum: VoteLockDatum) -> Bool {
  and {
    datum.proposal_id > 0,
    datum.locked_amount > 0,
    datum.voting_start < datum.voting_end,
  }
}

fn is_within_voting_period(
  validity_range: interval.Interval,
  voting_start: Int,
  voting_end: Int,
) -> Bool {
  and {
    interval.after(voting_start) |> interval.includes(validity_range),
    interval.is_entirely_before(validity_range, voting_end),
  }
}

fn is_after_voting_period(
  validity_range: interval.Interval,
  voting_end: Int,
) -> Bool {
  interval.is_entirely_after(validity_range, voting_end)
}

fn lock_is_preserved(datum: VoteLockDatum, tx: Transaction) -> Bool {
  when
    tx.inputs
      |> list.find(fn(input) { input.output.datum == InlineDatum(datum) })
  is {
    Some(Input {
      output: Output { value: spent_value, address: spent_address, .. },
      ..
    }) -> {
      let spent_has_locked_tokens = quantity_of(
        spent_value,
        datum.policy_id,
        datum.asset_name,
      ) >= datum.locked_amount

      let recreated_lock = list.any(
        tx.outputs,
        fn(output) {
          and {
            output.address.payment_credential == spent_address.payment_credential,
            output.datum == InlineDatum(datum),
            quantity_of(output.value, datum.policy_id, datum.asset_name) >= datum.locked_amount,
          }
        },
      )

      spent_has_locked_tokens && recreated_lock
    }
    None -> False
  }
}

fn can_cast_vote(
  datum: VoteLockDatum,
  vote: Int,
  expected_owner: VerificationKeyHash,
  quorum: Int,
  tx: Transaction,
) -> Bool {
  and {
    has_valid_datum(datum),
    datum.owner == expected_owner,
    vote >= quorum,
    is_within_voting_period(
      tx.validity_range,
      datum.voting_start,
      datum.voting_end,
    ),
    lock_is_preserved(datum, tx),
  }
}

fn can_unlock(
  datum: VoteLockDatum,
  expected_owner: VerificationKeyHash,
  tx: Transaction,
) -> Bool {
  and {
    has_valid_datum(datum),
    datum.owner == expected_owner,
    list.has(tx.extra_signatories, datum.owner),
    is_after_voting_period(tx.validity_range, datum.voting_end),
  }
}

validator dao(expected_owner: VerificationKeyHash, quorum: Int) {
  spend(
    datum: Option<VoteLockDatum>,
    redeemer: Redeemer,
    _utxo: Data,
    self: Transaction,
  ) {
    when datum is {
      Some(d) ->
        when redeemer is {
          CastVote { vote } ->
            can_cast_vote(d, vote, expected_owner, quorum, self)
          Unlock -> can_unlock(d, expected_owner, self)
        }
      None -> False
    }
  }

  else(_) {
    fail
  }
}

test accepts_well_formed_datum() {
  let datum = VoteLockDatum {
    proposal_id: 1,
    owner: #"0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c",
    policy_id: #"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    asset_name: #"544f4b454e",
    locked_amount: 10,
    voting_start: 1_000,
    voting_end: 2_000,
  }

  has_valid_datum(datum)
}

test rejects_invalid_voting_window() {
  let datum = VoteLockDatum {
    proposal_id: 1,
    owner: #"0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c",
    policy_id: #"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    asset_name: #"544f4b454e",
    locked_amount: 10,
    voting_start: 2_000,
    voting_end: 1_000,
  }

  !has_valid_datum(datum)
}

test voting_window_checks() {
  and {
    is_within_voting_period(interval.between(1_100, 1_900), 1_000, 2_000),
    !is_within_voting_period(interval.between(900, 1_900), 1_000, 2_000),
    !is_within_voting_period(interval.between(1_100, 2_000), 1_000, 2_000),
  }
}

test post_voting_window_checks() {
  and {
    is_after_voting_period(interval.after(2_001), 2_000),
    !is_after_voting_period(interval.after(2_000), 2_000),
  }
}
