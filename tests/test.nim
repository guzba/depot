import crunchy, depot/internal

const hmacSha256Tests = [
  (
    "abc",
    "def",
    "20ebc0f09344470134f35040f63ea98b1d8e414212949ee5c500429d15eab081"
  ),
  (
    "asdf3q5q23rfasf3a",
    "dfasdfasfd3qr3fqfaefa3fa3rfasadfasfdasdfasdfasdfasfdasd",
    "a1629e21b02776e7eacef6f615165d08894963a12dfbd304a47e7a8aff0a2dc5"
  ),
  (
    "awjieops;oi4etaawjieops;oi4etaawjieops;oi4etaawjieops;oi4etaawjieops;oi4",
    "p890y6t3q9ah2pqh8t6q3pth8qa3whu",
    "a1b7d6b597ae74f950dad4eb4dc1700420281b186abfaa321f728f38d675b099"
  )
]

for (a, b, c) in hmacSha256Tests:
  doAssert hmacSha256(a, b).toHex() == c
