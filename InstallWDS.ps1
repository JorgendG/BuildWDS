# iso gemaakt met een autounattend.xml
# oscdimg.exe -m -o -u2 -udfver102 -bootdata:2#p0,e,bc:\temp\iso\boot\etfsboot.com#pEF,e,bc:\temp\iso\efi\microsoft\boot\efisys.bin c:\temp\iso c:\temp\wds01.iso
start-transcript -path c:\windows\temp\installwds.txt

$sourcedir = "\\nasje\public\wim"

New-Item -ItemType Directory -Path c:\ -Name WDSImages
<#
Copy-Item -Path "$sourcedir\boot.wim" -Destination c:\WDSImages
Copy-Item -Path "$sourcedir\installw10_19h2.wim" -Destination c:\WDSImages
Copy-Item -Path "$sourcedir\install2019.wim" -Destination c:\WDSImages
Copy-Item -Path "$sourcedir\install2016.wim" -Destination c:\WDSImages
Copy-Item -Path "$sourcedir\install2012r2.wim" -Destination c:\WDSImages
Copy-Item -Path "$sourcedir\unattended.xml" -Destination c:\WDSImages
#>
Add-WindowsFeature WDS -includeall
& wdsutil.exe /initialize-server /reminst:'c:\remoteinstall' /standalone 
New-WdsInstallImageGroup -Name 'Windows 10' 
New-WdsInstallImageGroup -Name 'Windows Server 2019' 
New-WdsInstallImageGroup -Name 'Windows Server 2016' 
New-WdsInstallImageGroup -Name 'Windows Server 2012R2'
<#
Import-WdsBootImage -Path c:\wdsimages\boot.wim -NewDescription 'W2K16 WDS Boot'
Import-WdsInstallImage -Path c:\wdsimages\installw10_19h2.wim -ImageName 'Windows 10 Enterprise Evaluation' -ImageGroup 'Windows 10'
Import-WdsInstallImage -Path c:\wdsimages\install2019.wim -ImageName 'Windows Server 2019 SERVERSTANDARD' -ImageGroup 'Windows Server 2019'
Import-WdsInstallImage -Path c:\wdsimages\install2016.wim -ImageName 'Windows Server 2016 SERVERSTANDARD' -ImageGroup 'Windows Server 2016'
Import-WdsInstallImage -Path c:\wdsimages\install2012r2.wim -ImageName 'Windows Server 2012 R2 SERVERSTANDARD' -ImageGroup 'Windows Server 2012R2'
#>    
& wdsutil.exe /Set-Server /AnswerClients:All

Install-PackageProvider -Name "Nuget" -Force
Register-PackageSource -Name chocolatey -Location http://chocolatey.org/api/v2 -ProviderName NuGet -Trusted -Verbose
#Install-Package -Name sql-server-management-studio -ProviderName chocolatey -force

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main" -Name "DisableFirstRunCustomize" -Value 2

Find-Module -Name xPSDesiredStateConfiguration | Install-Module -Force
Find-Module -Name SqlServerDsc | Install-Module -Force

Invoke-WebRequest -Uri https://github.com/JorgendG/BuildWDS/raw/master/PullServerSQL.ps1 -OutFile $env:TEMP\PullServerSQL.ps1
& $env:TEMP\PullServerSQL.ps1
