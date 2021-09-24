$sslcert = Get-ChildItem -Path "Cert:\LocalMachine\My" | where { $_.Subject -eq 'CN=wds01' -and $_.Issuer -eq 'CN=wds01'  }
if( $null -eq $sslcert )
{
    $sslcert = New-SelfSignedCertificate -DnsName "wds01", "wds01.homelab.local" -CertStoreLocation "cert:\LocalMachine\My"
    $cert = Get-ChildItem -Path "Cert:\LocalMachine\My\$($sslcert.Thumbprint)"

    Export-Certificate -Cert $cert -FilePath C:\windows\temp\wds01.cer
}

configuration PullServerSQL 
{
    param(
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [PsCredential] $ShareCredentials

    )

    $sourcewim = '\\hyperdrive\public\wim'
    $sourcesql = '\\hyperdrive\public\sql\2017express'
    $sourcexenagent = '\\hyperdrive\public\agents\managementagentx64.msi'

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc
    Import-DscResource -ModuleName NetworkingDsc
    Import-DscResource -ModuleName SqlServerDsc
    Import-DscResource -ModuleName cWDS
    
    node localhost
    {

        WindowsFeature dscservice 
        {
            Name   = 'Dsc-Service'
            Ensure = 'Present'
        }

        File PullServerFiles 
        {
            DestinationPath = 'c:\pullserver'
            Ensure = 'Present'
            Type = 'Directory'
            Force = $true
        }

        WindowsFeature 'NetFramework45'
        {
            Name   = 'NET-Framework-45-Core'
            Ensure = 'Present'
        }

        PendingReboot Reboot 
        {
            Name             = "Reboot After Containers"
            SkipCcmClientSDK = $true 
	    }

        File managementagentx64 # $sourcexenagent = '\\hyperdrive\public\agents\managementagentx64.msi'
        {
            Ensure = 'Present'
            Type = 'File'
            SourcePath = $sourcexenagent
            DestinationPath = 'c:\Windows\temp\managementagentx64.msi'
            Credential = $ShareCredentials
            MatchSource = $false
        }

        Package CitrixHypervisorPVTools
        {
            Ensure      = "Present"  # You can also set Ensure to "Absent"
            Path        = "c:\Windows\temp\managementagentx64.msi"
            Name        = "Citrix Hypervisor PV Tools"
            ProductId   = "AC81AF0E-19F5-4A4F-B891-76166BF348ED"
            Arguments   = "/qn /norestart"
            DependsOn   = '[File]managementagentx64'
        }
    
        <#SqlSetup SqlExpress
        {
            InstanceName           = 'SQLEXPRESS'
            Features               = 'SQLENGINE'
            SQLSysAdminAccounts    = 'BUILTIN\Administrators', 'NT AUTHORITY\SYSTEM'
            SourcePath             = $sourcesql
            UpdateEnabled          = 'False'
            ForceReboot            = $false
            DependsOn              = '[WindowsFeature]NetFramework45'
        }#>

        xDscWebService PSDSCPullServer 
        {
            Ensure                       = 'Present'
            EndpointName                 = 'PSDSCPullServer'
            Port                         = 8080
            PhysicalPath                 = "$env:SystemDrive\inetpub\PSDSCPullServer"
            CertificateThumbPrint        = $sslcert.Thumbprint #'05DAA37D7A0013E346DC0FD0350DA79C3193A4AB'
            ModulePath                   = "c:\pullserver\Modules"
            ConfigurationPath            = "c:\pullserver\Configuration"
            State                        = 'Started'
            RegistrationKeyPath          = "c:\pullserver"
            UseSecurityBestPractices     = $true
            AcceptSelfSignedCertificates = $true
            ConfigureFirewall            = $false
            #SqlProvider                  = $true
            #SqlConnectionString          = 'Provider=SQLOLEDB.1;Server=.\sqlexpress;Database=DemoDSC;Integrated Security=SSPI;Initial Catalog=master;'
            DependsOn                    = '[File]PullServerFiles', '[WindowsFeature]dscservice'#, '[SqlSetup]SqlExpress'
        }

        Firewall Pullserver
        {
            Name                  = 'DSCPullServer_IIS_Port'
            DisplayName           = 'DSCPullServer_IIS_Port'
            Ensure                = 'Present'
            Enabled               = 'True'
            Profile               = ('Domain', 'Private', 'Public')
            Direction             = 'InBound'
            LocalPort             = ('8080')
            Protocol              = 'TCP'
            Description           = 'DSC Pullserver'
            DependsOn             = '[xDSCWebService]PSDSCPullServer'
        }


        File RegistrationKeyFile 
        {
            Ensure          = 'Present'
            Type            = 'File'
            DestinationPath = "c:\pullserver\RegistrationKeys.txt"
            Contents        = 'cb30127b-4b66-4f83-b207-c4801fb05087'
            DependsOn       = '[File]PullServerFiles'
        }

        File wdscert
        {
            Ensure = 'Present'
            Type = 'File'
            SourcePath = "C:\windows\temp\wds01.cer"
            DestinationPath = 'c:\inetpub\wwwroot\wds01.cer.txt'
            DependsOn = '[xDscWebService]PSDSCPullServer'
            MatchSource = $false
        }

        File DscPublicKey
        {
            Ensure = 'Present'
            Type = 'File'
            SourcePath = "C:\windows\temp\DscPublicKey.cer"
            DestinationPath = 'c:\pullserver\DscPublicKey.cer'
            DependsOn = '[xDscWebService]PSDSCPullServer'
            MatchSource = $false
        }


        WindowsFeature 'WDS'
        {
            Name   = 'WDS'
            Ensure = 'Present'
            IncludeAllSubFeature = $true
        }

        File wdsimagesfolder 
        {
            DestinationPath = 'c:\wdsimages'
            Ensure = 'Present'
            Type = 'Directory'
            Force = $true
        }

        File bootwim
        {
            Ensure = 'Present'
            Type = 'File'
            SourcePath = "$sourcewim\boot.wim"
            DestinationPath = 'c:\wdsimages\boot.wim'
            Credential = $ShareCredentials
            DependsOn = '[File]wdsimagesfolder'
            MatchSource = $false
        }

        File install2022wim
        {
            Ensure = 'Present'
            Type = 'File'
            SourcePath = "$sourcewim\install2022.wim"
            DestinationPath = 'c:\wdsimages\install2022.wim'
            Credential = $ShareCredentials
            DependsOn = '[File]wdsimagesfolder'
            MatchSource = $false
        }

        File install2019wim
        {
            Ensure = 'Present'
            Type = 'File'
            SourcePath = "$sourcewim\install2019.wim"
            DestinationPath = 'c:\wdsimages\install2019.wim'
            Credential = $ShareCredentials
            DependsOn = '[File]wdsimagesfolder'
            MatchSource = $false
        }


        File install2016wim
        {
            Ensure = 'Present'
            Type = 'File'
            SourcePath = "$sourcewim\install2016.wim"
            DestinationPath = 'c:\wdsimages\install2016.wim'
            Credential = $ShareCredentials
            DependsOn = '[File]wdsimagesfolder'
            MatchSource = $false
        }

        File install2012r2wim
        {
            Ensure = 'Present'
            Type = 'File'
            SourcePath = "$sourcewim\install2012r2.wim"
            DestinationPath = 'c:\wdsimages\install2012r2.wim'
            Credential = $ShareCredentials
            DependsOn = '[File]wdsimagesfolder'
            MatchSource = $false
        }

        File installw10wim
        {
            Ensure = 'Present'
            Type = 'File'
            SourcePath = "$sourcewim\installw10_19h2.wim"
            DestinationPath = 'c:\wdsimages\installw10_19h2.wim'
            Credential = $ShareCredentials
            DependsOn = '[File]wdsimagesfolder'
        }

        File installw11wim
        {
            Ensure = 'Present'
            Type = 'File'
            SourcePath = "$sourcewim\installw11.wim"
            DestinationPath = 'c:\wdsimages\installw11.wim'
            Credential = $ShareCredentials
            DependsOn = '[File]wdsimagesfolder'
        }

        cWDSInitialize InitWDS
        {
            Ensure = 'Present'
            RootFolder = "c:\remoteinstall"
            DependsOn = '[WindowsFeature]WDS'
        }

        cWDSInstallImage bootimage
        {
            Ensure = 'Present'
            ImageName = 'Microsoft Windows Setup (x64)'
            Path = 'c:\wdsimages\boot.wim'
            DependsOn = '[cWDSInitialize]InitWDS','[File]bootwim'
        }

        cWDSInstallImage server2022
        {
            Ensure = 'Present'
            ImageName = 'Windows Server 2022 SERVERSTANDARD'
            GroupName = 'Windows Server 2022'
            Path = 'c:\wdsimages\install2022.wim'
            Unattendfile = 'install2022.xml'
            DependsOn = '[cWDSInitialize]InitWDS','[File]install2022wim'
        }

        cWDSInstallImage server2019
        {
            Ensure = 'Present'
            ImageName = 'Windows Server 2019 SERVERSTANDARD'
            GroupName = 'Windows Server 2019'
            Path = 'c:\wdsimages\install2019.wim'
            Unattendfile = 'install2019.xml'
            DependsOn = '[cWDSInitialize]InitWDS','[File]install2019wim'
        }

        cWDSInstallImage server2016
        {
            Ensure = 'Present'
            ImageName = 'Windows Server 2016 SERVERSTANDARD'
            GroupName = 'Windows Server 2016'
            Path = 'c:\wdsimages\install2016.wim'
            Unattendfile = 'install2016.xml'
            DependsOn = '[cWDSInitialize]InitWDS','[File]install2016wim'
        }

        cWDSInstallImage server2012r2
        {
            Ensure = 'Present'
            ImageName = 'Windows Server 2012 R2 SERVERSTANDARD'
            GroupName = 'Windows Server 2012R2'
            Path = 'c:\wdsimages\install2012r2.wim'
            Unattendfile = 'install2012r2.xml'
            DependsOn = '[cWDSInitialize]InitWDS','[File]install2012r2wim'
        }

        cWDSInstallImage windows10
        {
            Ensure = 'Present'
            ImageName = 'Windows 10 Enterprise Evaluation'
            GroupName = 'Windows 10'
            Path = 'c:\wdsimages\installw10_19h2.wim'
            Unattendfile = 'installwin10.xml'
            DependsOn = '[cWDSInitialize]InitWDS','[File]installw10wim'
        }

        cWDSInstallImage windows11
        {
            Ensure = 'Present'
            ImageName = 'Windows 10 Enterprise'
            GroupName = 'Windows 11'
            Path = 'c:\wdsimages\installw11.wim'
            Unattendfile = 'installwin11.xml'
            DependsOn = '[cWDSInitialize]InitWDS','[File]installw11wim'
        }

        cWDSServerAnswer answerAll
        {
            Ensure = 'Present'
            Answer = 'all'
            DependsOn = '[cWDSInitialize]InitWDS'
        }

        cDSCModule ActiveDirectoryCSDsc
        {
            Ensure    = 'Present'
            DSCModule = 'ActiveDirectoryCSDsc'
            DependsOn  = '[xDscWebService]PSDSCPullServer'
        }

        cDSCModule XenDesktop7
        {
            Ensure    = 'Present'
            DSCModule = 'XenDesktop7'
            DependsOn  = '[xDscWebService]PSDSCPullServer'
        }

        cDSCModule SqlServerDsc
        {
            Ensure    = 'Present'
            DSCModule = 'SqlServerDsc'
            DependsOn  = '[xDscWebService]PSDSCPullServer'
        }

        cDSCModule ComputerManagementDsc
        {
            Ensure    = 'Present'
            DSCModule = 'ComputerManagementDsc'
            DependsOn  = '[xDscWebService]PSDSCPullServer'
        }

        cDSCModule ActiveDirectoryDsc
        {
            Ensure    = 'Present'
            DSCModule = 'ActiveDirectoryDsc'
            DependsOn  = '[xDscWebService]PSDSCPullServer'
        }

        cDSCModule xDnsServer
        {
            Ensure    = 'Present'
            DSCModule = 'xDnsServer'
            DependsOn  = '[xDscWebService]PSDSCPullServer'
        }

        cDSCModule cWDS
        {
            Ensure    = 'Present'
            DSCModule = 'cWDS'
            DependsOn  = '[xDscWebService]PSDSCPullServer'
        }

        cDSCModule NetworkingDsc
        {
            Ensure    = 'Present'
            DSCModule = 'NetworkingDsc'
            DependsOn  = '[xDscWebService]PSDSCPullServer'
        }

        cDSCModule xPSDesiredStateConfiguration
        {
            Ensure    = 'Present'
            DSCModule = 'xPSDesiredStateConfiguration'
            DependsOn  = '[xDscWebService]PSDSCPullServer'
        }

        cDSCModule PackageManagement
        {
            Ensure    = 'Present'
            DSCModule = 'PackageManagement'
            DependsOn  = '[xDscWebService]PSDSCPullServer'
        }

        xRemoteFile MakeDscConfigFile
        {
            DestinationPath = "C:\Pullserver\MakeDSCConfig.ps1"
            Uri = "https://github.com/JorgendG/BuildWDS/raw/master/MakeDSCConfig.ps1"
            DependsOn = '[File]PullServerFiles'
        }

        xRemoteFile BootstrapScript
        {
            DestinationPath = "C:\inetpub\wwwroot\Bootstrap.txt"
            Uri = "https://github.com/JorgendG/BuildWDS/raw/master/SetLCM.ps1"

            DependsOn = '[xDSCWebService]PSDSCPullServer'
        }

        xRemoteFile DscPrivatePublicKey
        {
            DestinationPath = "C:\inetpub\wwwroot\DscPrivatePublicKey.pfx.txt"
            Uri = " https://github.com/JorgendG/BuildWDS/raw/master/DscPrivatePublicKey.pfx"

            DependsOn = '[xDSCWebService]PSDSCPullServer'
        }

        WindowsFeature 'Web-Mgmt-Console'
        {
            Name   = 'Web-Mgmt-Console'
            Ensure = 'Present'
            IncludeAllSubFeature = $true
        }
    }


}


# Configure the LCM
Configuration ConfigureLCM {
    Node $AllNodes.NodeName {
         LocalConfigurationManager {
            RebootNodeIfNeeded = $true
            RefreshMode = 'Push'
            ConfigurationMode = 'ApplyAndAutoCorrect'
            ActionAfterReboot = 'ContinueConfiguration'
            #PSDscAllowPlainTextPassword = $true
         }
     }
 }
 
 # Configuration Data
 $ConfigData = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
        }
    )
 }

$SharePwd = "P@ssword!" | ConvertTo-SecureString -AsPlainText -Force
$ShareUserName = "hyperdrive\readonly"
$ShareCredentials = New-Object System.Management.Automation.PSCredential -ArgumentList $ShareUserName, $SharePwd

 
 # Compile the LCM Config
 ConfigureLCM `
       -OutputPath . `
       -ConfigurationData $ConfigData
       
 
 # Apply the LCM Config
 Set-DscLocalConfigurationManager `
       -Path .\ConfigureLCM\ `
       -ComputerName Localhost `
       -Verbose

$cd = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            PSDscAllowPlainTextPassword = $true
        }
    )
} 

PullServerSQL -ShareCredentials $ShareCredentials -ConfigurationData $cd 
Start-DscConfiguration -Path .\PullServerSQL -Verbose -wait -Force
