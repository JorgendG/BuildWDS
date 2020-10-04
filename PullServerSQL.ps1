Install-PackageProvider -Name "Nuget" -Force

Install-Module xPSDesiredStateConfiguration -Force
Install-Module xPendingReboot -Force
Install-Module SqlServerDsc -Force

#Register-PackageSource -Name chocolatey -Location http://chocolatey.org/api/v2 -ProviderName NuGet -Trusted -Verbose
#Install-Package -Name sql-server-management-studio -ProviderName chocolatey -force

Unregister-ScheduledTask -TaskName 'PullServerSQL' -Confirm:$false

& C:\Windows\Temp\ConfigPullServer.ps1
