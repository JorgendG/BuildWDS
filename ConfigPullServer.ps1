$sslcert = New-SelfSignedCertificate -DnsName "wds01", "wds01.homelab.local" -CertStoreLocation "cert:\LocalMachine\My"

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

    WindowsFeature 'Containers'
    {
        Name   = 'Containers'
        Ensure = 'Present'
    }

    xPendingReboot Reboot 
    {
        Name             = "Reboot After Containers"
        SkipCcmClientSDK = $true 
	}
    
    SqlSetup SqlExpress
    {
        InstanceName           = 'SQLEXPRESS'
        Features               = 'SQLENGINE'
        SQLSysAdminAccounts    = 'BUILTIN\Administrators', 'NT AUTHORITY\SYSTEM'
        SourcePath             = $sourcesql
        UpdateEnabled          = 'False'
        ForceReboot            = $false
        DependsOn              = '[WindowsFeature]NetFramework45'
    }

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
        SqlProvider                  = $true
        SqlConnectionString          = 'Provider=SQLOLEDB.1;Server=.\sqlexpress;Database=DemoDSC;Integrated Security=SSPI;Initial Catalog=master;'
        DependsOn                    = '[File]PullServerFiles', '[WindowsFeature]dscservice', '[SqlSetup]SqlExpress'
    }

    File RegistrationKeyFile 
    {
        Ensure          = 'Present'
        Type            = 'File'
        DestinationPath = "c:\pullserver\RegistrationKeys.txt"
        Contents        = 'cb30127b-4b66-4f83-b207-c4801fb05087'
        DependsOn       = '[File]PullServerFiles'
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

    cWDSInstallImage server2019
    {
        Ensure = 'Present'
        ImageName = 'Windows Server 2019 SERVERSTANDARD'
        GroupName = 'Windows Server 2019'
        Path = 'c:\wdsimages\install2019.wim'
        DependsOn = '[cWDSInitialize]InitWDS','[File]install2019wim'
    }

    Script Unattend2019
    {
        SetScript = {
            [xml]$xml = Get-Content C:\windows\temp\unattend.xml
            $winpe = $xml.unattend.settings | Where-Object{ $_.pass -eq 'windowsPE' }
            $winpe.component.Where( {$_.name -eq 'Microsoft-Windows-Setup'} ).WindowsDeploymentServices.ImageSelection.InstallImage.ImageName = 'Windows Server 2019 SERVERSTANDARD'
            $winpe.component.Where( {$_.name -eq 'Microsoft-Windows-Setup'} ).WindowsDeploymentServices.ImageSelection.InstallImage.ImageGroup = 'Windows Server 2019'
            $xml.Save( 'C:\remoteinstall\WdsClientUnattend\install2019.xml' )

        }
        GetScript = {
            return @{
                'Service' = 'C:\remoteinstall\WdsClientUnattend\install2019.xml'
            }
        }
        TestScript = {
            return (Test-Path 'C:\remoteinstall\WdsClientUnattend\install2019.xml')
        }
        DependsOn = '[cWDSInstallImage]server2019'
    }

    cWDSInstallImage server2016
    {
        Ensure = 'Present'
        ImageName = 'Windows Server 2016 SERVERSTANDARD'
        GroupName = 'Windows Server 2016'
        Path = 'c:\wdsimages\install2016.wim'
        DependsOn = '[cWDSInitialize]InitWDS','[File]install2016wim'
    }

    Script Unattend2016
    {
        SetScript = {
            [xml]$xml = Get-Content C:\windows\temp\unattend.xml
            $winpe = $xml.unattend.settings | Where-Object{ $_.pass -eq 'windowsPE' }
            $winpe.component.Where( {$_.name -eq 'Microsoft-Windows-Setup'} ).WindowsDeploymentServices.ImageSelection.InstallImage.ImageName = 'Windows Server 2016 SERVERSTANDARD'
            $winpe.component.Where( {$_.name -eq 'Microsoft-Windows-Setup'} ).WindowsDeploymentServices.ImageSelection.InstallImage.ImageGroup = 'Windows Server 2016'
            $xml.Save( 'C:\remoteinstall\WdsClientUnattend\install2016.xml' )

        }
        GetScript = {
            return @{
                'Service' = 'C:\remoteinstall\WdsClientUnattend\install2016.xml'
            }
        }
        TestScript = {
            return (Test-Path 'C:\remoteinstall\WdsClientUnattend\install2016.xml')
        }
        DependsOn = '[cWDSInstallImage]server2016'
    }

    cWDSInstallImage server2012r2
    {
        Ensure = 'Present'
        ImageName = 'Windows Server 2012 R2 SERVERSTANDARD'
        GroupName = 'Windows Server 2012R2'
        Path = 'c:\wdsimages\install2012r2.wim'
        DependsOn = '[cWDSInitialize]InitWDS','[File]install2012r2wim'
    }

    Script Unattend2012r2
    {
        SetScript = {
            [xml]$xml = Get-Content C:\windows\temp\unattend.xml
            $winpe = $xml.unattend.settings | Where-Object{ $_.pass -eq 'windowsPE' }
            $winpe.component.Where( {$_.name -eq 'Microsoft-Windows-Setup'} ).WindowsDeploymentServices.ImageSelection.InstallImage.ImageName = 'Windows Server 2012 R2 SERVERSTANDARD'
            $winpe.component.Where( {$_.name -eq 'Microsoft-Windows-Setup'} ).WindowsDeploymentServices.ImageSelection.InstallImage.ImageGroup = 'Windows Server 2012R2'
            $xml.Save( 'C:\remoteinstall\WdsClientUnattend\install2012r2.xml' )

        }
        GetScript = {
            return @{
                'Service' = 'C:\remoteinstall\WdsClientUnattend\install2012r2.xml'
            }
        }
        TestScript = {
            return (Test-Path 'C:\remoteinstall\WdsClientUnattend\install2012r2.xml')
        }
        DependsOn = '[cWDSInstallImage]server2012r2'
    }

    cWDSInstallImage windows10
    {
        Ensure = 'Present'
        ImageName = 'Windows 10 Enterprise Evaluation'
        GroupName = 'Windows 10'
        Path = 'c:\wdsimages\installw10_19h2.wim'
        DependsOn = '[cWDSInitialize]InitWDS','[File]installw10wim'
    }

    Script Unattendwin10
    {
        SetScript = {
            [xml]$xml = Get-Content C:\windows\temp\unattend.xml
            $winpe = $xml.unattend.settings | Where-Object{ $_.pass -eq 'windowsPE' }
            $winpe.component.Where( {$_.name -eq 'Microsoft-Windows-Setup'} ).WindowsDeploymentServices.ImageSelection.InstallImage.ImageName = 'Windows 10 Enterprise Evaluation'
            $winpe.component.Where( {$_.name -eq 'Microsoft-Windows-Setup'} ).WindowsDeploymentServices.ImageSelection.InstallImage.ImageGroup = 'Windows 10'
            $xml.Save( 'C:\remoteinstall\WdsClientUnattend\installwin10.xml' )

        }
        GetScript = {
            return @{
                'Service' = 'C:\remoteinstall\WdsClientUnattend\installwin10.xml'
            }
        }
        TestScript = {
            return (Test-Path 'C:\remoteinstall\WdsClientUnattend\installwin10.xml')
        }
        DependsOn = '[cWDSInstallImage]windows10'
    }

    cWDSServerAnswer answerAll
    {
        Ensure = 'Present'
        Answer = 'all'
        DependsOn = '[cWDSInitialize]InitWDS'
    }

    Script DockerService {
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
                   NodeName                    = 'localhost'
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
