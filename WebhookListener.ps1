Add-Type -AssemblyName System.Web

$HttpListener = New-Object System.Net.HttpListener
$HttpListener.Prefixes.Add("http://+:1234/")

$HttpListener.Start()
While ($HttpListener.IsListening) {
    $HttpContext = $HttpListener.GetContext()
    $HttpRequest = $HttpContext.Request
    $RequestUrl = $HttpRequest.Url.OriginalString
    Write-Output "$RequestUrl"
    if($HttpRequest.HasEntityBody) 
    {
        $Reader = New-Object System.IO.StreamReader($HttpRequest.InputStream)
        $bla = $Reader.ReadToEnd()
        $decodedpayload = [System.Web.HttpUtility]::UrlDecode($bla)
        $whevent = $decodedpayload -replace "payload=", "["
        $whevent = $whevent + "]"

        $whevent = ConvertFrom-Json $whevent

        Write-Output "Files modified:"
        $whevent[0].head_commit.modified
        if( 'MakeDSCConfig.ps1' -in $whevent[0].head_commit.modified )
        {
            Invoke-WebRequest -Uri https://github.com/JorgendG/BuildWDS/raw/master/MakeDSCConfig.ps1 -OutFile C:\Pullserver\MakeDSCConfig.ps1
        }
        if( 'MakeDSCConfig.psd1' -in $whevent[0].head_commit.modified )
        {
            Invoke-WebRequest -Uri https://github.com/JorgendG/BuildWDS/raw/master/MakeDSCConfig.psd1 -OutFile C:\Pullserver\MakeDSCConfig.psd1
        }
        Write-Output "Files added:"
        $whevent[0].head_commit.added
        
        #Write-Output $decodedpayload
    }
    $HttpResponse = $HttpContext.Response
    $HttpResponse.Headers.Add("Content-Type","text/plain")
    $HttpResponse.StatusCode = 200
    $ResponseBuffer = [System.Text.Encoding]::UTF8.GetBytes("")
    $HttpResponse.ContentLength64 = $ResponseBuffer.Length
    $HttpResponse.OutputStream.Write($ResponseBuffer,0,$ResponseBuffer.Length)
    $HttpResponse.Close()
    Write-Output "" # Newline
    #$HttpListener.Stop()
}
$HttpListener.Stop()
