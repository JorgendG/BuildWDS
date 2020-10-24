Install-PackageProvider -Name "Nuget" -Force

Install-Module -Name xPSDesiredStateConfiguration -Force
Install-Module -Name xPendingReboot -Force
Install-Module -Name ComputerManagementDsc -Force
Install-Module -Name SqlServerDsc -Force

#Get-Module xPendingReboot -ListAvailable | Publish-ModuleToPullServer -PullServerWebConfig "$env:SystemDrive\inetpub\PSDSCPullServer\web.config"

#Register-PackageSource -Name chocolatey -Location http://chocolatey.org/api/v2 -ProviderName NuGet -Trusted -Verbose
#Install-Package -Name sql-server-management-studio -ProviderName chocolatey -force

Unregister-ScheduledTask -TaskName 'PullServerSQL' -Confirm:$false

& C:\Windows\Temp\ConfigPullServer.ps1
