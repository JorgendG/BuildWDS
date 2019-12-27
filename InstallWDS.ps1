$sourcedir = "\\nasje\public\wim"

New-Item -ItemType Directory -Path c:\ -Name WDSImages
Copy-Item -Path "$sourcedir\boot.wim" -Destination c:\WDSImages
Copy-Item -Path "$sourcedir\install2016.wim" -Destination c:\WDSImages
Copy-Item -Path "$sourcedir\install2012r2.wim" -Destination c:\WDSImages
Copy-Item -Path "$sourcedir\unattended.xml" -Destination c:\WDSImages
Add-WindowsFeature WDS -includeall
& wdsutil.exe /initialize-server /reminst:'c:\remoteinstall' /standalone 
New-WdsInstallImageGroup -Name 'Windows Server 2016' 
New-WdsInstallImageGroup -Name 'Windows Server 2012R2'
Import-WdsBootImage -Path c:\wdsimages\boot.wim -NewDescription 'W2K16 WDS Boot'
Import-WdsInstallImage -Path c:\wdsimages\install2016.wim -ImageName 'Windows Server 2016 SERVERSTANDARD' -ImageGroup 'Windows Server 2016'
Import-WdsInstallImage -Path c:\wdsimages\install2012r2.wim -ImageName 'Windows Server 2012 R2 SERVERSTANDARD' -ImageGroup 'Windows Server 2012R2'
    
& wdsutil.exe /Set-Server /AnswerClients:All

