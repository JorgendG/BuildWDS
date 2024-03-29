Unregister-ScheduledTask -TaskName 'InstallDSCModules' -Confirm:$false


# Install DSC Modules
Install-PackageProvider -Name "Nuget" -Force

$requiredmodules = 'xPSDesiredStateConfiguration', 'ComputerManagementDsc', 'SqlServerDsc', 'NetworkingDsc', 'DnsServerDsc', 'xDefender'
Install-Module $requiredmodules -Force

#Install custom DSC WDS module
New-Item -Path 'C:\Program Files\WindowsPowerShell\Modules\cWDS' -ItemType Directory
$githubrepo = 'https://raw.githubusercontent.com/JorgendG/cWDS/master'
Invoke-WebRequest -Uri "$githubrepo/cWDS.psd1" -OutFile 'C:\Program Files\WindowsPowerShell\Modules\cWDS\cWDS.psd1'
Invoke-WebRequest -Uri "$githubrepo/cWDS.psm1" -OutFile 'C:\Program Files\WindowsPowerShell\Modules\cWDS\cWDS.psm1'

$githubrepo = 'https://raw.githubusercontent.com/JorgendG/BuildWDS/master'
Invoke-WebRequest -Uri "$githubrepo/DscPrivatePublicKey.pfx" -OutFile C:\Windows\Temp\DscPrivatePublicKey.pfx
Invoke-WebRequest -Uri "$githubrepo/DscPublicKey.cer" -OutFile C:\Windows\Temp\DscPublicKey.cer
$mypwd = ConvertTo-SecureString -String "1234" -Force -AsPlainText
Import-PfxCertificate -FilePath C:\Windows\Temp\DscPrivatePublicKey.pfx -Password $mypwd -CertStoreLocation Cert:\LocalMachine\My

# Download and run the DSC config
$githubrepo = 'https://raw.githubusercontent.com/JorgendG/BuildWDS/master'
Invoke-WebRequest -Uri "$githubrepo/WDSServer/ConfigPullServer.psd1" -OutFile C:\Windows\Temp\ConfigPullServer.psd1
Invoke-WebRequest -Uri "$githubrepo/WDSServer/ConfigPullServer.ps1" -OutFile C:\Windows\Temp\ConfigPullServer.ps1

& C:\Windows\Temp\ConfigPullServer.ps1
