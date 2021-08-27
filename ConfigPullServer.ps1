$sslcert = Get-ChildItem -Path "Cert:\LocalMachine\My" | where { $_.Subject -eq 'CN=wds01' -and $_.Issuer -eq 'CN=wds01'  }
if( $null -eq $sslcert )
{
    $sslcert = New-SelfSignedCertificate -DnsName "wds01", "wds01.homelab.local" -CertStoreLocation "cert:\LocalMachine\My"
    $cert = Get-ChildItem -Path "Cert:\LocalMachine\My\$($sslcert.Thumbprint)"

    Export-Certificate -Cert $cert -FilePath C:\windows\temp\wds01.cer
}

configuration PullServerSQL 
{
    $sourcewim = '\\nasje\public\wim'
    $sourcesql = '\\nasje\public\sql\2017express'

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName xPendingReboot
    Import-DscResource -ModuleName SqlServerDsc
    Import-DscResource -ModuleName cWDS
    

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

    <#WindowsFeature 'Containers'
    {
        Name   = 'Containers'
        Ensure = 'Present'
        LogPath = 'c:\windows\temp\containerfeature.txt'
    }#>

    xPendingReboot Reboot 
    {
        Name             = "Reboot After Containers"
        SkipCcmClientSDK = $true 
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
        #SqlProvider                  = $true
        #SqlConnectionString          = 'Provider=SQLOLEDB.1;Server=.\sqlexpress;Database=DemoDSC;Integrated Security=SSPI;Initial Catalog=master;'
        DependsOn                    = '[File]PullServerFiles', '[WindowsFeature]dscservice'#, '[SqlSetup]SqlExpress'
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
        DependsOn = '[File]wdsimagesfolder'
        MatchSource = $false
    }

    File install2022wim
    {
        Ensure = 'Present'
        Type = 'File'
        SourcePath = "$sourcewim\install2022.wim"
        DestinationPath = 'c:\wdsimages\install2022.wim'
        DependsOn = '[File]wdsimagesfolder'
        MatchSource = $false
    }

    File install2019wim
    {
        Ensure = 'Present'
        Type = 'File'
        SourcePath = "$sourcewim\install2019.wim"
        DestinationPath = 'c:\wdsimages\install2019.wim'
        DependsOn = '[File]wdsimagesfolder'
        MatchSource = $false
    }


    File install2016wim
    {
        Ensure = 'Present'
        Type = 'File'
        SourcePath = "$sourcewim\install2016.wim"
        DestinationPath = 'c:\wdsimages\install2016.wim'
        DependsOn = '[File]wdsimagesfolder'
        MatchSource = $false
    }

    File install2012r2wim
    {
        Ensure = 'Present'
        Type = 'File'
        SourcePath = "$sourcewim\install2012r2.wim"
        DestinationPath = 'c:\wdsimages\install2012r2.wim'
        DependsOn = '[File]wdsimagesfolder'
        MatchSource = $false
    }

    File installw10wim
    {
        Ensure = 'Present'
        Type = 'File'
        SourcePath = "$sourcewim\installw10_19h2.wim"
        DestinationPath = 'c:\wdsimages\installw10_19h2.wim'
        DependsOn = '[File]wdsimagesfolder'
    }

    File installw11wim
    {
        Ensure = 'Present'
        Type = 'File'
        SourcePath = "$sourcewim\installw11.wim"
        DestinationPath = 'c:\wdsimages\installw11.wim'
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

    <#Script DockerService {
        SetScript = {
            Install-Module DockerMsftProvider -Force
            Install-Package Docker -ProviderName DockerMsftProvider -Force
        }
        GetScript = {
            return @{
                'Service' = (Get-Service -Name Docker).Name
            }
        }
        TestScript = {
            if (Get-Service -Name Docker -ErrorAction SilentlyContinue) {
                return $True
            }
            return $False
        }
        DependsOn = '[windowsfeature]containers'
    }

    Service DockerService{
        Name = 'Docker'
        State = 'Running'
        Ensure = 'Present'
        DependsOn = '[Script]DockerService'
    }#>

    cDSCModule ActiveDirectoryCSDsc
    {
        Ensure    = 'Present'
        DSCModule = 'ActiveDirectoryCSDsc'
        DependsOn  = '[xDscWebService]PSDSCPullServer'
    }

    cDSCModule xPendingReboot
    {
        Ensure    = 'Present'
        DSCModule = 'xPendingReboot'
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
 $ConfigData = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
        }
    )
 }
 
 # Compile the LCM Config
 ConfigureLCM `
       -OutputPath . `
       -ConfigurationData $ConfigData
 
 # Apply the LCM Config
 Set-DscLocalConfigurationManager `
       -Path .\ConfigureLCM\ `
       -ComputerName Localhost `
       -Verbose
 

PullServerSQL
Start-DscConfiguration -Path .\PullServerSQL -Verbose -wait -Force
