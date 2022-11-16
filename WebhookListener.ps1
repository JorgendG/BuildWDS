<#
$nssm = 'c:\pullserver\nssm.exe'
$serviceName = 'GitHubWebHook'
$powershell = (Get-Command powershell).Source
$scriptPath = 'C:\pullserver\githubseintje.ps1'
$arguments = '-ExecutionPolicy Bypass -NoProfile -File "{0}"' -f $scriptPath
& $nssm install $serviceName $powershell $arguments
& $nssm status $serviceName
Start-Service $serviceName
Get-Service $serviceName
#>

Add-Type -AssemblyName System.Web

$HttpListener = New-Object System.Net.HttpListener
$HttpListener.Prefixes.Add("http://+:1234/")

$HttpListener.Start()
While ($HttpListener.IsListening) {
    $getMakeDSCConfigps1 = $false
    $getMakeDSCConfigpsd1 = $false

    $HttpContext = $HttpListener.GetContext()
    $HttpRequest = $HttpContext.Request
    $RequestUrl = $HttpRequest.Url.OriginalString
    Write-Output "$RequestUrl"
    if ($HttpRequest.HasEntityBody) {
        $Reader = New-Object System.IO.StreamReader($HttpRequest.InputStream)
        $bla = $Reader.ReadToEnd()
        $decodedpayload = [System.Web.HttpUtility]::UrlDecode($bla)
        $whevent = $decodedpayload -replace "payload=", "["
        $whevent = $whevent + "]"

        $whevent = ConvertFrom-Json $whevent

        Write-Output "Files modified:"
        $whevent[0].head_commit.modified
        if ( 'MakeDSCConfig.ps1' -in $whevent[0].head_commit.modified ) {
            $getMakeDSCConfigps1 = $true
        }
        if ( 'MakeDSCConfig.psd1' -in $whevent[0].head_commit.modified ) {
            $getMakeDSCConfigpsd1 = $true
        }
        Write-Output "Files added:"
        $whevent[0].head_commit.added
        
        #Write-Output $decodedpayload
    }
    $HttpResponse = $HttpContext.Response
    $HttpResponse.Headers.Add("Content-Type", "text/plain")
    $HttpResponse.StatusCode = 200
    $ResponseBuffer = [System.Text.Encoding]::UTF8.GetBytes("")
    $HttpResponse.ContentLength64 = $ResponseBuffer.Length
    $HttpResponse.OutputStream.Write($ResponseBuffer, 0, $ResponseBuffer.Length)
    $HttpResponse.Close()
    Write-Output "" # Newline
    #$HttpListener.Stop()
    if ( $getMakeDSCConfigps1 ) {
        Invoke-WebRequest -Uri https://github.com/JorgendG/BuildWDS/raw/master/MakeDSCConfig.ps1 -OutFile C:\Pullserver\MakeDSCConfig.ps1
    }
    if ( $getMakeDSCConfigpsd1 ) {
        Invoke-WebRequest -Uri https://github.com/JorgendG/BuildWDS/raw/master/MakeDSCConfig.psd1 -OutFile C:\Pullserver\MakeDSCConfig.psd1
    }
    # trap makeconfig af
}
$HttpListener.Stop()
