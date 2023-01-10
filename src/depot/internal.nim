import crunchy

proc `$`*(a: array[32, uint8]): string =
  result.setLen(32)
  copyMem(result[0].addr, a[0].unsafeAddr, 32)

proc hmacSha256*(key, data: string): array[32, uint8] =
  const
    blockSize = 64
    ipad = 0x36
    opad = 0x5c

  var blockSizeKey =
    if key.len > blockSize:
      $sha256(key)
    else:
      key
  if blockSizeKey.len < blockSize:
    blockSizeKey.setLen(blockSize)

  proc applyXor(s: string, value: uint8): string =
    result = s
    for c in result.mitems:
      c = (c.uint8 xor value).char

  sha256(
    applyXor(blockSizeKey, opad) &
    $sha256(applyXor(blockSizeKey, ipad) & data)
  )
