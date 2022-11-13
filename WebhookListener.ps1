
$HttpListener = New-Object System.Net.HttpListener
$HttpListener.Prefixes.Add("http://+:1234/")

$HttpListener.Start()
While ($HttpListener.IsListening) {
    $HttpContext = $HttpListener.GetContext()
    $HttpRequest = $HttpContext.Request
    $RequestUrl = $HttpRequest.Url.OriginalString
    Write-Output "$RequestUrl"
    if($HttpRequest.HasEntityBody) {
      $Reader = New-Object System.IO.StreamReader($HttpRequest.InputStream)
      $bla = $Reader.ReadToEnd()
      $decodedpayload = [System.Web.HttpUtility]::UrlDecode($bla)
      Write-Output $decodedpayload
    }
    $HttpResponse = $HttpContext.Response
    $HttpResponse.Headers.Add("Content-Type","text/plain")
    $HttpResponse.StatusCode = 200
    $ResponseBuffer = [System.Text.Encoding]::UTF8.GetBytes("")
    $HttpResponse.ContentLength64 = $ResponseBuffer.Length
    $HttpResponse.OutputStream.Write($ResponseBuffer,0,$ResponseBuffer.Length)
    $HttpResponse.Close()
    Write-Output "" # Newline
    $HttpListener.Stop()
}
#$HttpListener.Stop()

$decodedpayload
$decodedpayload2 = $decodedpayload -replace "payload=","["
#$decodedpayload2[-1] = "]"
$len = $decodedpayload2.Length - 1
$decodedpayload2[$len]
$decodedpayload2 = $decodedpayload2 -replace ".$"
$decodedpayload2 = $decodedpayload2 + "]"
ConvertFrom-Json $decodedpayload2
