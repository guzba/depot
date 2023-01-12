import crunchy

proc hmacSha256*(key, data: string): array[32, uint8] =
  const
    blockSize = 64
    ipad = 0x36
    opad = 0x5c

  var blockSizeKey =
    if key.len > blockSize:
      let hashedKey = sha256(key)
      var s = newString(32)
      copyMem(s[0].addr, hashedKey[0].unsafeAddr, 32)
      s
    else:
      key
  if blockSizeKey.len < blockSize:
    blockSizeKey.setLen(blockSize)

  proc applyXor(s: string, value: uint8): string =
    result = s
    for c in result.mitems:
      c = (c.uint8 xor value).char

  let h = sha256(applyXor(blockSizeKey, ipad) & data)

  var s = applyXor(blockSizeKey, opad)
  s.setLen(s.len + 32)
  copyMem(s[s.len - 32].addr, h[0].unsafeAddr, 32)

  sha256(s)
