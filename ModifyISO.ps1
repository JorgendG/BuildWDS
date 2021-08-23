Invoke-WebRequest -Uri 'https://download.microsoft.com/download/1/f/d/1fd2291e-c0e9-4ae0-beae-fbbe0fe41a5a/adk/Installers/1ac6852d8cf69114a2f7c4872d489325.cab' -OutFile 'C:\Windows\Temp\1ac6852d8cf69114a2f7c4872d489325.cab'
Invoke-WebRequest -Uri 'https://download.microsoft.com/download/1/f/d/1fd2291e-c0e9-4ae0-beae-fbbe0fe41a5a/adk/Installers/Oscdimg (DesktopEditions)-x86_en-us.msi' -OutFile 'C:\Windows\Temp\Oscdimg (DesktopEditions)-x86_en-us.msi'
Invoke-WebRequest -Uri 'https://download.microsoft.com/download/1/f/d/1fd2291e-c0e9-4ae0-beae-fbbe0fe41a5a/adk/Installers/52be7e8e9164388a9e6c24d01f6f1625.cab' -OutFile 'C:\Windows\Temp\52be7e8e9164388a9e6c24d01f6f1625.cab'
Invoke-WebRequest -Uri 'https://download.microsoft.com/download/1/f/d/1fd2291e-c0e9-4ae0-beae-fbbe0fe41a5a/adk/Installers/9d2b092478d6cca70d5ac957368c00ba.cab' -OutFile 'C:\Windows\Temp\9d2b092478d6cca70d5ac957368c00ba.cab'
Invoke-WebRequest -Uri 'https://download.microsoft.com/download/1/f/d/1fd2291e-c0e9-4ae0-beae-fbbe0fe41a5a/adk/Installers/5d984200acbde182fd99cbfbe9bad133.cab' -OutFile 'C:\Windows\Temp\5d984200acbde182fd99cbfbe9bad133.cab'
Invoke-WebRequest -Uri 'https://download.microsoft.com/download/1/f/d/1fd2291e-c0e9-4ae0-beae-fbbe0fe41a5a/adk/Installers/bbf55224a0290f00676ddc410f004498.cab' -OutFile 'C:\Windows\Temp\bbf55224a0290f00676ddc410f004498.cab'

$MSIArguments = @(
        "/i"
        ('"{0}"' -f 'C:\Windows\Temp\Oscdimg (DesktopEditions)-x86_en-us.msi')
        "/qn"
        "/norestart"
    )
Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait -NoNewWindow
