import crunchy

proc hmacSha256*(key, data: openarray[uint8]): array[32, uint8] =
  const
    blockSize = 64
    ipad = 0x36
    opad = 0x5c

  var blockSizeKey: array[blockSize, uint8]
  if key.len > blockSize:
    let hash = sha256(key)
    copyMem(blockSizeKey[0].addr, hash[0].unsafeAddr, hash.len)
  else:
    copyMem(blockSizeKey[0].addr, key[0].unsafeAddr, key.len)

  proc applyXor(s: array[64, uint8], value: uint8): array[64, uint8] =
    result = s
    for c in result.mitems:
      c = (c xor value)

  let ipadXor = applyXor(blockSizeKey, ipad)

  let h1 =
    if data.len > 0:
      var s = newString(ipadXor.len + data.len)
      copyMem(s[0].addr, ipadXor[0].unsafeAddr, ipadXor.len)
      copyMem(s[ipadXor.len].addr, data[0].unsafeAddr, data.len)
      sha256(s)
    else:
      sha256(ipadXor)

  let opadXor = applyXor(blockSizeKey, opad)

  var s2 = newString(opadXor.len + 32)
  copyMem(s2[0].addr, opadXor[0].unsafeAddr, opadXor.len)
  copyMem(s2[opadXor.len].addr, h1[0].unsafeAddr, 32)

  sha256(s2)

proc hmacSha256*(
  key, data: string
): array[32, uint8] {.inline.} =
  hmacSha256(
    key.toOpenArrayByte(0, key.high),
    data.toOpenArrayByte(0, data.high)
  )

proc hmacSha256*(
  key: string,
  data: openarray[byte]
): array[32, uint8] {.inline.} =
  hmacSha256(
    key.toOpenArrayByte(0, key.high),
    data
  )

proc hmacSha256*(
  key: openarray[byte],
  data: string
): array[32, uint8] {.inline.} =
  hmacSha256(
    key,
    data.toOpenArrayByte(0, data.high)
  )
