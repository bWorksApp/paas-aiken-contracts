use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use aiken/interval
use cardano/transaction.{Transaction}

pub type KycDatum {
  customer: VerificationKeyHash,
  reviewer: VerificationKeyHash,
  kyc_level: Int,
  expires_at: Int,
  verified: Bool,
}

pub type Redeemer {
  Approve { level: Int, expiry: Int }
  Revoke
}

fn has_valid_datum(datum: KycDatum) -> Bool {
  and {
    datum.kyc_level >= 1,
    datum.expires_at > 0,
    datum.customer != datum.reviewer,
  }
}

fn can_approve(
  datum: KycDatum,
  expected_reviewer: VerificationKeyHash,
  level: Int,
  expiry: Int,
  tx: Transaction,
) -> Bool {
  and {
    has_valid_datum(datum),
    datum.reviewer == expected_reviewer,
    list.has(tx.extra_signatories, expected_reviewer),
    !datum.verified,
    level >= 1,
    expiry > datum.expires_at,
    interval.is_entirely_before(tx.validity_range, expiry),
  }
}

fn can_revoke(
  datum: KycDatum,
  expected_reviewer: VerificationKeyHash,
  tx: Transaction,
) -> Bool {
  and {
    has_valid_datum(datum),
    datum.reviewer == expected_reviewer,
    list.has(tx.extra_signatories, expected_reviewer),
    datum.verified,
    interval.is_entirely_before(tx.validity_range, datum.expires_at),
  }
}

validator kyc(expected_reviewer: VerificationKeyHash) {
  spend(
    datum: Option<KycDatum>,
    redeemer: Redeemer,
    _utxo: Data,
    self: Transaction,
  ) {
    when datum is {
      Some(d) ->
        when redeemer is {
          Approve { level, expiry } ->
            can_approve(d, expected_reviewer, level, expiry, self)
          Revoke -> can_revoke(d, expected_reviewer, self)
        }
      None -> False
    }
  }

  else(_) {
    fail
  }
}

test valid_datum_passes_basic_checks() {
  let datum = KycDatum {
    customer: #"0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c",
    reviewer: #"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f",
    kyc_level: 2,
    expires_at: 2_000,
    verified: False,
  }

  has_valid_datum(datum)
}

test invalid_datum_rejected() {
  let datum = KycDatum {
    customer: #"0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c",
    reviewer: #"0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c",
    kyc_level: 0,
    expires_at: 0,
    verified: False,
  }

  !has_valid_datum(datum)
}
