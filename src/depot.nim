import crunchy, std/algorithm, std/strutils, std/times, webby

export webby

const
  dateFormat = initTimeFormat("yyyyMMdd")
  dateTimeFormat = initTimeFormat("yyyyMMdd\'T\'HHmmss\'Z\'")

type
  DepotError* = object of CatchableError

  DepotClient* = object
    accessKey*: string
    secretKey*: string
    region*: string
    endpoint*: string

proc initDepotClient*(
  accessKey, secretKey, region, endpoint: string
): DepotClient =
  result.accessKey = accessKey
  result.secretKey = secretKey
  result.region = region
  result.endpoint = endpoint

proc makeCanonicalRequest(
  httpMethod: string,
  uri: string,
  params: QueryParams,
  headers: seq[(string, string)],
  signedHeaders: string
): string =
  result = httpmethod.toUpperAscii() & '\n'
  result &= uri & '\n'
  result &= $params & '\n'
  for (k, v) in headers:
    result &= k & ":" & v & '\n'
  result &= '\n'
  result &= signedHeaders & '\n'
  result &= "UNSIGNED-PAYLOAD"

proc makeCredentialScope(date, region, service: string): string =
  date & '/' &
  region.toLowerAscii() & '/' &
  service.toLowerAscii() &
  "/aws4_request"

proc makeStringToSign(
  dateTime, credentialScope, hashedCanonicalRequest: string
): string =
  "AWS4-HMAC-SHA256\n" &
  dateTime & '\n' &
  credentialScope & '\n' &
  hashedCanonicalRequest

proc getPresignedUrl*(
  client: DepotClient,
  action: string,
  bucket: string,
  objectKey: string,
  httpMethod: string,
  headers: HttpHeaders,
  query = emptyQueryParams(),
  expires = 604800 # 7 days
): string {.raises: [DepotError].} =
  ## Generates a presigned URL. Presigned URLs can be used to grant temporary
  ## access to your S3-compatible service resources.
  ## action: https://docs.aws.amazon.com/AmazonS3/latest/API/API_Operations.html
  ## bucket: The name of the bucket
  ## objectKey: The key for the object in the bucket, such as /folder/name.ext
  ## httpMethod: PUT, POST, GET etc depending on the HTTP request for the URL
  ## headers: The HTTP headers to sign (must match when using the URL)
  ## expires: [1 .. 604800] seconds the signed URL is valid for

  # See https://docs.aws.amazon.com/general/latest/gr/create-signed-request.html

  if "host" notin headers:
    raise newException(DepotError, "Host header is required for presigned URLs")

  var uri = "/" & bucket
  if objectKey != "":
    if objectKey[0] == '/':
      uri &= objectKey
    else:
      uri &= '/' & objectKey

  let
    nowUtc = getTime().utc()
    date = nowUtc.format(dateFormat)
    dateTime = nowUtc.format(dateTimeFormat)
    credentialScope = makeCredentialScope(
      date,
      client.region,
      "s3"
    )

  var sortedHeaders = seq[(string, string)] headers
  for (k, v) in sortedHeaders.mitems:
    k = k.toLowerAscii()
  sortedHeaders.sort(proc(a, b: (string, string)): int = cmp(a[0], b[0]))

  var signedHeaders: seq[string]
  for (k, _) in sortedHeaders:
    signedHeaders.add(k)

  var params: QueryParams
  params["Action"] = action
  params["X-Amz-Algorithm"] = "AWS4-HMAC-SHA256"
  params["X-Amz-Credential"] = client.accessKey & "/" & credentialScope
  params["X-Amz-Date"] = dateTime
  params["X-Amz-Expires"] = $expires
  params["X-Amz-SignedHeaders"] = signedHeaders.join(";")
  params.add(query)

  let
    canonicalRequest = makeCanonicalRequest(
      httpMethod,
      uri,
      params,
      sortedHeaders,
      signedHeaders.join(";")
    )
    stringToSign = makeStringToSign(
      dateTime,
      credentialScope,
      sha256(canonicalRequest).toHex()
    )
    kDate = hmacSha256("AWS4" & client.secretKey, date)
    kRegion = hmacSha256(kDate, client.region)
    kService = hmacSha256(kRegion, "s3")
    kSigning = hmacSha256(kService, "aws4_request")
    signature = hmacSha256(kSigning, stringToSign).toHex()

  params["X-Amz-Signature"] = signature

  if client.endpoint != "":
    if not client.endpoint.startsWith("http"):
      result = "https://"
    result &= client.endpoint
  if result != "" and result[^1] == '/':
    result.setLen(result.len - 1) # Trim trailing /
  result &= uri & "?" & $params
