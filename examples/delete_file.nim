import depot, puppy

## This example shows how to use Depot to create a presigned URL to delete an
## object from a bucket. This example then uses Puppy to make the HTTP request.
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
## automatically include a Host header based on the URL domain so
## it is important when you create the signed URL that it will match the Host
## header the browser will use.

var headers: HttpHeaders
headers["Host"] = s3.endpoint

## Generate the presigned URL.

let url = s3.getPresignedUrl(
  "DeleteObject", # Action
  "BUCKET",
  "OBJECT_KEY",
  "DELETE", # HTTP method
  headers # Headers to sign
)

## Use the presigned URL.

let response = delete(url, headers)
if response.code == 204:
  echo "Deleted!"
else:
  echo "Request failed: ", response.code, " ", response.body
