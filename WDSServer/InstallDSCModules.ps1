Install-PackageProvider -Name "Nuget" -Force

Install-Module -Name xPSDesiredStateConfiguration -Force
Install-Module -Name ComputerManagementDsc -Force
Install-Module -Name SqlServerDsc -Force
Install-Module -Name NetworkingDsc -Force
Install-Module -Name DnsServerDsc -Force
Install-Module -Name xDefender -Force

New-Item -Path 'C:\Program Files\WindowsPowerShell\Modules\cWDS' -ItemType Directory
Invoke-WebRequest -Uri https://github.com/JorgendG/cWDS/raw/master/cWDS.psd1 -OutFile 'C:\Program Files\WindowsPowerShell\Modules\cWDS\cWDS.psd1'
Invoke-WebRequest -Uri https://github.com/JorgendG/cWDS/raw/master/cWDS.psm1 -OutFile 'C:\Program Files\WindowsPowerShell\Modules\cWDS\cWDS.psm1'


Unregister-ScheduledTask -TaskName 'InstallDSCModules' -Confirm:$false

& C:\Windows\Temp\ConfigPullServer.ps1
