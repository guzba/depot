import std/bitops, std/endians, std/strutils

const k = [
  0x428a2f98'u32, 0x71374491'u32, 0xb5c0fbcf'u32, 0xe9b5dba5'u32,
  0x3956c25b'u32, 0x59f111f1'u32, 0x923f82a4'u32, 0xab1c5ed5'u32,
  0xd807aa98'u32, 0x12835b01'u32, 0x243185be'u32, 0x550c7dc3'u32,
  0x72be5d74'u32, 0x80deb1fe'u32, 0x9bdc06a7'u32, 0xc19bf174'u32,
  0xe49b69c1'u32, 0xefbe4786'u32, 0x0fc19dc6'u32, 0x240ca1cc'u32,
  0x2de92c6f'u32, 0x4a7484aa'u32, 0x5cb0a9dc'u32, 0x76f988da'u32,
  0x983e5152'u32, 0xa831c66d'u32, 0xb00327c8'u32, 0xbf597fc7'u32,
  0xc6e00bf3'u32, 0xd5a79147'u32, 0x06ca6351'u32, 0x14292967'u32,
  0x27b70a85'u32, 0x2e1b2138'u32, 0x4d2c6dfc'u32, 0x53380d13'u32,
  0x650a7354'u32, 0x766a0abb'u32, 0x81c2c92e'u32, 0x92722c85'u32,
  0xa2bfe8a1'u32, 0xa81a664b'u32, 0xc24b8b70'u32, 0xc76c51a3'u32,
  0xd192e819'u32, 0xd6990624'u32, 0xf40e3585'u32, 0x106aa070'u32,
  0x19a4c116'u32, 0x1e376c08'u32, 0x2748774c'u32, 0x34b0bcb5'u32,
  0x391c0cb3'u32, 0x4ed8aa4a'u32, 0x5b9cca4f'u32, 0x682e6ff3'u32,
  0x748f82ee'u32, 0x78a5636f'u32, 0x84c87814'u32, 0x8cc70208'u32,
  0x90befffa'u32, 0xa4506ceb'u32, 0xbef9a3f7'u32, 0xc67178f2'u32
]

when defined(amd64):
  import nimsimd/sse41, nimsimd/runtimecheck

  when defined(gcc) or defined(clang):
    {.localPassc: "-msse4.1 -msha".}

  {.push header: "immintrin.h".}
  proc mm_sha256msg1_epu32(a, b: M128i): M128i {.importc: "_mm_sha256msg1_epu32".}
  proc mm_sha256msg2_epu32(a, b: M128i): M128i {.importc: "_mm_sha256msg2_epu32".}
  proc mm_sha256rnds2_epu32(a, b, k: M128i): M128i {.importc: "_mm_sha256rnds2_epu32".}
  {.pop.}

  proc x64sha256(state: var array[8, uint32], data: string) =
    let mask = mm_set_epi64x(0x0c0d0e0f08090a0b, 0x0405060700010203)

    var
      tmp = mm_loadu_si128(state[0].addr)
      state1 = mm_loadu_si128(state[4].addr)

    tmp = mm_shuffle_epi32(tmp, 0xb1)
    state1 = mm_shuffle_epi32(state1, 0x1b)

    var state0 = mm_alignr_epi8(tmp, state1, 8)

    state1 = mm_blend_epi16(state1, tmp, 0xf0)

    var
      pos = 0
      abefSave, cdghSave: M128i
      msg, msg0, msg1, msg2, msg3: M128i
    for _ in 0 ..< data.len div 64:
      # Save current state
      abefSave = state0
      cdghSave = state1

      # Rounds 0-3
      msg = mm_loadu_si128(data[pos].unsafeAddr)
      msg0 = mm_shuffle_epi8(msg, mask)
      msg = mm_add_epi32(msg0, mm_set_epi64x(0xE9B5DBA5B5C0FBCF, 0x71374491428A2F98))
      state1 = mm_sha256rnds2_epu32(state1, state0, msg)
      msg = mm_shuffle_epi32(msg, 0x0E)
      state0 = mm_sha256rnds2_epu32(state0, state1, msg)

      # Rounds 4-7
      msg1 = mm_loadu_si128(data[pos + 16].unsafeAddr)
      msg1 = mm_shuffle_epi8(msg1, mask)
      msg = mm_add_epi32(msg1, mm_set_epi64x(0xAB1C5ED5923F82A4, 0x59F111F13956C25B))
      state1 = mm_sha256rnds2_epu32(state1, state0, msg)
      msg = mm_shuffle_epi32(msg, 0x0E)
      state0 = mm_sha256rnds2_epu32(state0, state1, msg)
      msg0 = mm_sha256msg1_epu32(msg0, msg1)

      # Rounds 8-11
      msg2 = mm_loadu_si128(data[pos + 32].unsafeAddr)
      msg2 = mm_shuffle_epi8(msg2, mask)
      msg = mm_add_epi32(msg2, mm_set_epi64x(0x550C7DC3243185BE, 0x12835B01D807AA98))
      state1 = mm_sha256rnds2_epu32(state1, state0, msg)
      msg = mm_shuffle_epi32(msg, 0x0E)
      state0 = mm_sha256rnds2_epu32(state0, state1, msg)
      msg1 = mm_sha256msg1_epu32(msg1, msg2)

      # Rounds 12-15
      msg3 = mm_loadu_si128(data[pos + 48].unsafeAddr)
      msg3 = mm_shuffle_epi8(msg3, mask)
      msg = mm_add_epi32(msg3, mm_set_epi64x(0xC19BF1749BDC06A7, 0x80DEB1FE72BE5D74))
      state1 = mm_sha256rnds2_epu32(state1, state0, msg)
      tmp = mm_alignr_epi8(msg3, msg2, 4)
      msg0 = mm_add_epi32(msg0, tmp)
      msg0 = mm_sha256msg2_epu32(msg0, msg3)
      msg = mm_shuffle_epi32(msg, 0x0E)
      state0 = mm_sha256rnds2_epu32(state0, state1, msg)
      msg2 = mm_sha256msg1_epu32(msg2, msg3)

      # Rounds 16-19
      msg = mm_add_epi32(msg0, mm_set_epi64x(0x240CA1CC0FC19DC6, 0xEFBE4786E49B69C1))
      state1 = mm_sha256rnds2_epu32(state1, state0, msg)
      tmp = mm_alignr_epi8(msg0, msg3, 4)
      msg1 = mm_add_epi32(msg1, tmp)
      msg1 = mm_sha256msg2_epu32(msg1, msg0)
      msg = mm_shuffle_epi32(msg, 0x0E)
      state0 = mm_sha256rnds2_epu32(state0, state1, msg)
      msg3 = mm_sha256msg1_epu32(msg3, msg0)

      # Rounds 20-23
      msg = mm_add_epi32(msg1, mm_set_epi64x(0x76F988DA5CB0A9DC, 0x4A7484AA2DE92C6F))
      state1 = mm_sha256rnds2_epu32(state1, state0, msg)
      tmp = mm_alignr_epi8(msg1, msg0, 4)
      msg2 = mm_add_epi32(msg2, tmp)
      msg2 = mm_sha256msg2_epu32(msg2, msg1)
      msg = mm_shuffle_epi32(msg, 0x0E)
      state0 = mm_sha256rnds2_epu32(state0, state1, msg)
      msg0 = mm_sha256msg1_epu32(msg0, msg1)

      # Rounds 24-27
      msg = mm_add_epi32(msg2, mm_set_epi64x(0xBF597FC7B00327C8, 0xA831C66D983E5152))
      state1 = mm_sha256rnds2_epu32(state1, state0, msg)
      tmp = mm_alignr_epi8(msg2, msg1, 4)
      msg3 = mm_add_epi32(msg3, tmp)
      msg3 = mm_sha256msg2_epu32(msg3, msg2)
      msg = mm_shuffle_epi32(msg, 0x0E)
      state0 = mm_sha256rnds2_epu32(state0, state1, msg)
      msg1 = mm_sha256msg1_epu32(msg1, msg2)

      # Rounds 28-31
      msg = mm_add_epi32(msg3, mm_set_epi64x(0x1429296706CA6351,  0xD5A79147C6E00BF3))
      state1 = mm_sha256rnds2_epu32(state1, state0, msg)
      tmp = mm_alignr_epi8(msg3, msg2, 4)
      msg0 = mm_add_epi32(msg0, tmp)
      msg0 = mm_sha256msg2_epu32(msg0, msg3)
      msg = mm_shuffle_epi32(msg, 0x0E)
      state0 = mm_sha256rnds2_epu32(state0, state1, msg)
      msg2 = mm_sha256msg1_epu32(msg2, msg3)

      # Rounds 32-35
      msg = mm_add_epi32(msg0, mm_set_epi64x(0x53380D134D2C6DFC, 0x2E1B213827B70A85))
      state1 = mm_sha256rnds2_epu32(state1, state0, msg)
      tmp = mm_alignr_epi8(msg0, msg3, 4)
      msg1 = mm_add_epi32(msg1, tmp)
      msg1 = mm_sha256msg2_epu32(msg1, msg0)
      msg = mm_shuffle_epi32(msg, 0x0E)
      state0 = mm_sha256rnds2_epu32(state0, state1, msg)
      msg3 = mm_sha256msg1_epu32(msg3, msg0)

      # Rounds 36-39
      msg = mm_add_epi32(msg1, mm_set_epi64x(0x92722C8581C2C92E, 0x766A0ABB650A7354))
      state1 = mm_sha256rnds2_epu32(state1, state0, msg)
      tmp = mm_alignr_epi8(msg1, msg0, 4)
      msg2 = mm_add_epi32(msg2, tmp)
      msg2 = mm_sha256msg2_epu32(msg2, msg1)
      msg = mm_shuffle_epi32(msg, 0x0E)
      state0 = mm_sha256rnds2_epu32(state0, state1, msg)
      msg0 = mm_sha256msg1_epu32(msg0, msg1)

      # Rounds 40-43
      msg = mm_add_epi32(msg2, mm_set_epi64x(0xC76C51A3C24B8B70, 0xA81A664BA2BFE8A1))
      state1 = mm_sha256rnds2_epu32(state1, state0, msg)
      tmp = mm_alignr_epi8(msg2, msg1, 4)
      msg3 = mm_add_epi32(msg3, tmp)
      msg3 = mm_sha256msg2_epu32(msg3, msg2)
      msg = mm_shuffle_epi32(msg, 0x0E)
      state0 = mm_sha256rnds2_epu32(state0, state1, msg)
      msg1 = mm_sha256msg1_epu32(msg1, msg2)

      # Rounds 44-47
      msg = mm_add_epi32(msg3, mm_set_epi64x(0x106AA070F40E3585, 0xD6990624D192E819))
      state1 = mm_sha256rnds2_epu32(state1, state0, msg)
      tmp = mm_alignr_epi8(msg3, msg2, 4)
      msg0 = mm_add_epi32(msg0, tmp)
      msg0 = mm_sha256msg2_epu32(msg0, msg3)
      msg = mm_shuffle_epi32(msg, 0x0E)
      state0 = mm_sha256rnds2_epu32(state0, state1, msg)
      msg2 = mm_sha256msg1_epu32(msg2, msg3)

      # Rounds 48-51
      msg = mm_add_epi32(msg0, mm_set_epi64x(0x34B0BCB52748774C, 0x1E376C0819A4C116))
      state1 = mm_sha256rnds2_epu32(state1, state0, msg)
      tmp = mm_alignr_epi8(msg0, msg3, 4)
      msg1 = mm_add_epi32(msg1, tmp)
      msg1 = mm_sha256msg2_epu32(msg1, msg0)
      msg = mm_shuffle_epi32(msg, 0x0E)
      state0 = mm_sha256rnds2_epu32(state0, state1, msg)
      msg3 = mm_sha256msg1_epu32(msg3, msg0)

      # Rounds 52-55
      msg = mm_add_epi32(msg1, mm_set_epi64x(0x682E6FF35B9CCA4F, 0x4ED8AA4A391C0CB3))
      state1 = mm_sha256rnds2_epu32(state1, state0, msg)
      tmp = mm_alignr_epi8(msg1, msg0, 4)
      msg2 = mm_add_epi32(msg2, tmp)
      msg2 = mm_sha256msg2_epu32(msg2, msg1)
      msg = mm_shuffle_epi32(msg, 0x0E)
      state0 = mm_sha256rnds2_epu32(state0, state1, msg)

      # Rounds 56-59
      msg = mm_add_epi32(msg2, mm_set_epi64x(0x8CC7020884C87814, 0x78A5636F748F82EE))
      state1 = mm_sha256rnds2_epu32(state1, state0, msg)
      tmp = mm_alignr_epi8(msg2, msg1, 4)
      msg3 = mm_add_epi32(msg3, tmp)
      msg3 = mm_sha256msg2_epu32(msg3, msg2)
      msg = mm_shuffle_epi32(msg, 0x0E)
      state0 = mm_sha256rnds2_epu32(state0, state1, msg)

      # Rounds 60-63
      msg = mm_add_epi32(msg3, mm_set_epi64x(0xC67178F2BEF9A3F7, 0xA4506CEB90BEFFFA))
      state1 = mm_sha256rnds2_epu32(state1, state0, msg)
      msg = mm_shuffle_epi32(msg, 0x0E)
      state0 = mm_sha256rnds2_epu32(state0, state1, msg)

      # Combine state
      state0 = mm_add_epi32(state0, abefSave)
      state1 = mm_add_epi32(state1, cdghSave)

      pos += 64

    tmp = mm_shuffle_epi32(state0, 0x1b)
    state1 = mm_shuffle_epi32(state1, 0xb1)
    state0 = mm_blend_epi16(tmp, state1, 0xf0)
    state1 = mm_alignr_epi8(state1, tmp, 8)

    mm_storeu_si128(state[0].addr, state0)
    mm_storeu_si128(state[4].addr, state1)

  let canUseIntrinsics = checkInstructionSets({SSE41, SHA})

proc sha256*(s: string): array[32, uint8] =
  var data = s
  data.add 0b10000000.char
  while data.len mod 64 != 56:
    data.add 0.char
  data.setLen(data.len + 8)
  var L = s.len.uint64 * 8
  swapEndian64(data[data.len - 8].addr, L.addr)

  var state = [
    0x6a09e667'u32, 0xbb67ae85'u32, 0x3c6ef372'u32, 0xa54ff53a'u32,
    0x510e527f'u32, 0x9b05688c'u32, 0x1f83d9ab'u32, 0x5be0cd19'u32
  ]

  var usedIntrinsics: bool
  when defined(amd64):
    if canUseIntrinsics:
      x64sha256(state, data)
      usedIntrinsics = true

  if not usedIntrinsics:
    # See https://blog.boot.dev/cryptography/how-sha-2-works-step-by-step-sha-256/
    var
      pos: int
      w: array[64, uint32]
    for _ in 0 ..< data.len div 64:
      # Copy 64 bytes (16 uint32) into w from data
      # This cannot just be a copyMem due to byte ordering
      for i in 0 ..< 16:
        var value: uint32
        swapEndian32(value.addr, data[pos + i * 4].addr)
        w[i] = value

      for i in 16 ..< 64:
        let
          s0 =
            rotateRightBits(w[i - 15], 7) xor
            rotateRightBits(w[i - 15], 18) xor
            (w[i - 15] shr 3)
          s1 =
            rotateRightBits(w[i - 2], 17) xor
            rotateRightBits(w[i - 2], 19) xor
            (w[i - 2] shr 10)
        w[i] = w[i - 16] + s0 + w[i - 7] + s1

      var
        a = state[0]
        b = state[1]
        c = state[2]
        d = state[3]
        e = state[4]
        f = state[5]
        g = state[6]
        h = state[7]
      for i in 0 ..< 64:
        let
          S1 =
            rotateRightBits(e, 6) xor
            rotateRightBits(e, 11) xor
            rotateRightBits(e, 25)
          ch = (e and f) xor ((not e) and g)
          temp1 = h + S1 + ch + k[i] + w[i]
          S0 =
            rotateRightBits(a, 2) xor
            rotateRightBits(a, 13) xor
            rotateRightBits(a, 22)
          maj = (a and b) xor (a and c) xor (b and c)
          temp2 = S0 + maj
        h = g
        g = f
        f = e
        e = d + temp1
        d = c
        c = b
        b = a
        a = temp1 + temp2

      state[0] += a
      state[1] += b
      state[2] += c
      state[3] += d
      state[4] += e
      state[5] += f
      state[6] += g
      state[7] += h
      pos += 64

  for i in 0 ..< state.len:
    swapEndian32(result[i * 4].addr, state[i].addr)

proc toHex*(a: array[32, uint8]): string =
  result = newStringOfCap(64)
  for i in 0 ..< a.len:
    result.add toHex(a[i], 2)
  result = result.toLowerAscii()

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
