


configuration PullServerSQL 
{
    $sourcewim = '\\nasje\public\wim'
    $sourcesql = '\\nasje\public\sql\2017express'

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
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

    SqlSetup SqlExpress
    {
        InstanceName           = 'SQLEXPRESS'
        Features               = 'SQLENGINE'
        SQLSysAdminAccounts    = 'BUILTIN\Administrators', 'NT AUTHORITY\SYSTEM'
        SourcePath             = $sourcesql
        UpdateEnabled          = 'False'
        ForceReboot            = $false
        DependsOn            = '[WindowsFeature]NetFramework45'
    }

    xDscWebService PSDSCPullServer 
    {
        Ensure                       = 'Present'
        EndpointName                 = 'PSDSCPullServer'
        Port                         = 8080
        PhysicalPath                 = "$env:SystemDrive\inetpub\PSDSCPullServer"
        CertificateThumbPrint        = 'AllowUnencryptedTraffic'
        ModulePath                   = "c:\pullserver\Modules"
        ConfigurationPath            = "c:\pullserver\Configuration"
        State                        = 'Started'
        RegistrationKeyPath          = "c:\pullserver"
        UseSecurityBestPractices     = $false
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
        SourcePath = "'$sourcewim\install2019.wim"
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

    cWDSInstallImage server2016
    {
        Ensure = 'Present'
        ImageName = 'Windows Server 2016 SERVERSTANDARD'
        GroupName = 'Windows Server 2016'
        Path = 'c:\wdsimages\install2016.wim'
        DependsOn = '[cWDSInitialize]InitWDS','[File]install2016wim'
    }

    cWDSInstallImage server2012r2
    {
        Ensure = 'Present'
        ImageName = 'Windows Server 2012 R2 SERVERSTANDARD'
        GroupName = 'Windows Server 2012R2'
        Path = 'c:\wdsimages\install2012r2.wim'
        DependsOn = '[cWDSInitialize]InitWDS','[File]install2012r2wim'
    }

    cWDSInstallImage windows10
    {
        Ensure = 'Present'
        ImageName = 'Windows 10 Enterprise Evaluation'
        GroupName = 'Windows 10'
        Path = 'c:\wdsimages\installw10_19h2.wim'
        DependsOn = '[cWDSInitialize]InitWDS','[File]installw10wim'
    }

    cWDSServerAnswer answerAll
    {
        Ensure = 'Present'
        Answer = 'all'
        DependsOn = '[cWDSInstallImage]windows10'
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
}

PullServerSQL
Start-DscConfiguration -Path .\PullServerSQL -Verbose -wait -Force
