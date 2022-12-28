# Depot

`nimble install depot`

![Github Actions](https://github.com/guzba/depot/workflows/Github%20Actions/badge.svg)

[API reference](https://nimdocs.com/guzba/depot)

Depot is a helpful companion for working with S3-compatible storage provider APIs.

Some examples of S3-compatible storage APIs include:

* [Amazon S3](https://aws.amazon.com/s3/)
* [Google Cloud Storage](https://cloud.google.com/storage/)
* [Cloudflare R2](https://www.cloudflare.com/products/r2/)
* [Backblaze B2](https://www.backblaze.com/b2/cloud-storage.html)

⚠️ Currently this repo only provides an easy way to generate presigned URLs. Fortunately, presigned URLs are all that you actually need to interact with these APIs. Unfortunately, this is not as simple as a complete Depot API will be.

## Example

```nim
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

var headers: HttpHeaders
headers["Host"] = s3.endpoint

## Generate the presigned URL.

let url = s3.getPresignedUrl(
  "PutObject", # Action
  "BUCKET",
  "OBJECT_KEY",
  "PUT", # HTTP method
  headers # Headers to sign
)

## Add any headers that are not signed.

headers["Content-Type"] = "text/html"

## Use the presigned URL to upload a simple HTML file.

let response = put(url, headers, "<span>Hello, World!</span>")
if response.code == 200:
  echo "Upload!"
else:
  echo "Upload failed: ", response.code, " ", response.body
```

More examples can be found in the [examples/]() directory.
