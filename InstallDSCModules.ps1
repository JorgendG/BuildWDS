Install-PackageProvider -Name "Nuget" -Force

Install-Module -Name xPSDesiredStateConfiguration -Force
Install-Module -Name ComputerManagementDsc -Force
Install-Module -Name SqlServerDsc -Force
Install-Module -Name NetworkingDsc -Force

Unregister-ScheduledTask -TaskName 'InstallDSCModules' -Confirm:$false

& C:\Windows\Temp\ConfigPullServer.ps1
