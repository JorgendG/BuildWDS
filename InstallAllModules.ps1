Get-Module xPSDesiredStateConfiguration -ListAvailable | Publish-ModuleToPullServer -PullServerWebConfig "$env:SystemDrive\inetpub\PSDSCPullServer\web.config"
Install-Module xActiveDirectory -Force
Get-Module xActiveDirectory -ListAvailable | Publish-ModuleToPullServer -PullServerWebConfig "$env:SystemDrive\inetpub\PSDSCPullServer\web.config"
Install-Module xComputerManagement -Force
Get-Module xComputerManagement -ListAvailable | Publish-ModuleToPullServer -PullServerWebConfig "$env:SystemDrive\inetpub\PSDSCPullServer\web.config"
Install-Module xPendingReboot -Force
Get-Module xPendingReboot -ListAvailable | Publish-ModuleToPullServer -PullServerWebConfig "$env:SystemDrive\inetpub\PSDSCPullServer\web.config"
Install-Module xNetworking -Force
Get-Module xNetworking -ListAvailable | Publish-ModuleToPullServer -PullServerWebConfig "$env:SystemDrive\inetpub\PSDSCPullServer\web.config"
Install-Module xDnsServer -Force
Get-Module xDnsServer -ListAvailable | Publish-ModuleToPullServer -PullServerWebConfig "$env:SystemDrive\inetpub\PSDSCPullServer\web.config"
Install-Module xSQLServer -Force
Get-Module xSQLServer -ListAvailable | Publish-ModuleToPullServer -PullServerWebConfig "$env:SystemDrive\inetpub\PSDSCPullServer\web.config"
Install-Module XenDesktop7 -Force
Get-Module XenDesktop7 -ListAvailable | Publish-ModuleToPullServer -PullServerWebConfig "$env:SystemDrive\inetpub\PSDSCPullServer\web.config"

Get-Module cComputername -ListAvailable | Publish-ModuleToPullServer -PullServerWebConfig "$env:SystemDrive\inetpub\PSDSCPullServer\web.config"

