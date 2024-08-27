use aiken/transaction.{ScriptContext}
 
type Datum {
  number: Int,
  string: ByteArray,
}
 
type Redeemer {
  number: Int,
  string: ByteArray,
}
 
validator {
  fn datum_redeemer_logicsdatum_redeemer_logics(datum: Datum, redeemer: Redeemer, _context: ScriptContext) -> Bool {
    let is_same_string =
      redeemer.string == datum.string
 
  let is_same_number =
      redeemer.number == datum.number
      
    is_same_string && is_same_number
  }
}