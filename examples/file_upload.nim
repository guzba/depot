import depot, puppy

## This example shows how to use Depot to create a presigned URL for
## a file upload. This example then uses Puppy to upload the file.
## You can use Nim's HttpClient, AsyncHttpClient, or any other HTTP client
## instead.

## Set up the DepotClient for the S3-compatible service you're using.
const s3 = initDepotClient(
  "ACCESS_KEY",
  "SECRET_KEY",
  "REGION", # Example: us-east-2
  "ENDPOINT" # Example: s3.us-east-2.amazonaws.com
)

## The headers to sign. These must be included and match exactly when using
## the presigned URL. The Host header is required.

## Note that when using presigned URLs in JavaScript, the browser will
## automatically include a Host header based on the current domain so
## it is important when you create the signed URL that it will match the Host
## header the browser will use.

var headers: HttpHeaders
headers["Host"] = s3.endpoint

## Generate the presigned URL.

let url = s3.getPresignedUrl(
  "PutObject", # Action
  "BUCKET",
  "OBJECT_KEY",
  "PUT", # HTTP method
  headers, # Headers to sign
  expires = 300 # 5 minutes
)

## Add any headers that are not signed.

headers["Content-Type"] = "text/html"

## Use the presigned URL to upload a simple HTML file.

let response = put(url, headers, "<span>Hello, World!</span>")
if response.code == 200:
  echo "Upload!"
else:
  echo "Upload failed: ", response.code, " ", response.body
