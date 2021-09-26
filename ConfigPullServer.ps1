$sslcert = Get-ChildItem -Path "Cert:\LocalMachine\My" | where { $_.Subject -eq 'CN=wds01' -and $_.Issuer -eq 'CN=wds01'  }
if( $null -eq $sslcert )
{
    $sslcert = New-SelfSignedCertificate -DnsName "wds01", "wds01.homelabdc22.local" -CertStoreLocation "cert:\LocalMachine\My"
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

    #$sourcewim = '\\hyperdrive\public\wim'
    $sourcesql = '\\hyperdrive\public\sql\2017express'
    $sourcexenagent = '\\hyperdrive\public\agents\managementagentx64.msi'

    $wimfiles = $ConfigData.WimFiles
    $DSCModules = $ConfigData.DSCModules

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

        File managementagentx64
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
            Ensure      = "Present" 
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

        cWDSInitialize InitWDS
        {
            Ensure = 'Present'
            RootFolder = "c:\remoteinstall"
            DependsOn = '[WindowsFeature]WDS'
        }

        Foreach($WimFile in $WimFiles)
        {
            File "FileCopy-$($WimFile.Name)" 
            {
                Ensure = 'Present'
                Type = 'File'
                DependsOn = '[File]wdsimagesfolder'

                SourcePath = $WimFile.SourcePath
                DestinationPath = $WimFile.DestinationPath
            }

            cWDSInstallImage "WDSInstallImage-$($WimFile.Name)"
            {
                Ensure = 'Present'
                ImageName = $WimFile.ImageName
                GroupName = $WimFile.GroupName
                Path = $WimFile.DestinationPath
                Unattendfile = $WimFile.Unattendfile
                DependsOn = '[cWDSInitialize]InitWDS',"[File]FileCopy-$($WimFile.Name)" 
            }
        }
      
        cWDSServerAnswer answerAll
        {
            Ensure = 'Present'
            Answer = 'all'
            DependsOn = '[cWDSInitialize]InitWDS'
        }

        Foreach($DSCModule in $DSCModules)
        {
            cDSCModule "DSCModule-$($DSCModule.Name)"
            {
                Ensure    = 'Present'
                DSCModule = $DSCModule.Name
                DependsOn  = '[xDscWebService]PSDSCPullServer'
            }
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
         }
     }
 }
 
 # Configuration Data
 $sourcewim = '\\hyperdrive\public\wim'
 $ConfigData = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser = $true
        }
    )
    WimFiles = @(
        @{
            Name = 'Boot'
            SourcePath = "$sourcewim\boot.wim"
            DestinationPath = 'c:\wdsimages\boot.wim'
            ImageName = 'Microsoft Windows Setup (x64)'
        },
        @{
            Name = 'Server2022'
            SourcePath = "$sourcewim\install2022.wim"
            DestinationPath = 'c:\wdsimages\install2022.wim'
            ImageName = 'Windows Server 2022 SERVERSTANDARD'
            GroupName = 'Windows Server 2022'
            Unattendfile = 'install2022.xml'
        },
        @{
            Name = 'Server2019'
            SourcePath = "$sourcewim\install2019.wim"
            DestinationPath = 'c:\wdsimages\install2019.wim'
            ImageName = 'Windows Server 2019 SERVERSTANDARD'
            GroupName = 'Windows Server 2019'
            Unattendfile = 'install2019.xml'
        },
        @{
            Name = 'Server2016'
            SourcePath = "$sourcewim\install2016.wim"
            DestinationPath = 'c:\wdsimages\install2016.wim'
            ImageName = 'Windows Server 2016 SERVERSTANDARD'
            GroupName = 'Windows Server 2016'
            Unattendfile = 'install2016.xml'
        },
        @{
            Name = 'Server2012R2'
            SourcePath = "$sourcewim\install2012r2.wim"
            DestinationPath = 'c:\wdsimages\install2012r2.wim'
            ImageName = 'Windows Server 2012 R2 SERVERSTANDARD'
            GroupName = 'Windows Server 2012R2'
            Unattendfile = 'install2012r2.xml'
        },
        ,
        @{
            Name = 'Windows10'
            SourcePath = "$sourcewim\installw10_19h2.wim"
            DestinationPath = 'c:\wdsimages\installw10_19h2.wim'
            ImageName = 'Windows 10 Enterprise Evaluation'
            GroupName = 'Windows 10'
            Unattendfile = 'installwin10.xml'
        }
        ,
        @{
            Name = 'Windows11'
            SourcePath = "$sourcewim\installw11.wim"
            DestinationPath = 'c:\wdsimages\installw11.wim'
            ImageName = 'Windows 10 Enterprise'
            GroupName = 'Windows 11'
            Unattendfile = 'installwin11.xml'
        }
    )
    DSCModules = @(
        @{
            Name = 'ActiveDirectoryDsc'
        },
        @{
            Name = 'xDnsServer'
        },
        @{
            Name = 'cWDS'
        },
        @{
            Name = 'NetworkingDsc'
        },
        @{
            Name = 'xPSDesiredStateConfiguration'
        },
        @{
            Name = 'PackageManagement'
        },
        @{
            Name = 'XenDesktop7'
        },
        @{
            Name = 'ActiveDirectoryCSDsc'
        },
        @{
            Name = 'SqlServerDsc'
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


PullServerSQL -ShareCredentials $ShareCredentials -ConfigurationData $ConfigData
Start-DscConfiguration -Path .\PullServerSQL -Verbose -wait -Force
