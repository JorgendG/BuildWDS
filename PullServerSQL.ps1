configuration PullServerSQL 
{
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

    SqlSetup SqlExpress
    {
        InstanceName           = 'SQLEXPRESS'
        Features               = 'SQLENGINE'
        SQLSysAdminAccounts    = 'BUILTIN\Administrators', 'NT AUTHORITY\SYSTEM'
        SourcePath             = '\\nasje\public\sql\2017express'
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

    cWDSInitialize InitWDS
    {
        Ensure = 'Present'
        RootFolder = "c:\remoteinstall"
    }

    cWDSInstallImage bootimage
    {
        Ensure = 'Present'
        ImageName = 'Microsoft Windows Setup (x64)'
        Path = 'c:\wdsimages\boot.wim'
        DependsOn = '[cWDSInitialize]InitWDS'
    }

    cWDSInstallImage server2019
    {
        Ensure = 'Present'
        ImageName = 'Windows Server 2019 SERVERSTANDARD'
        GroupName = 'Windows Server 2019'
        Path = 'c:\wdsimages\install2019.wim'
        DependsOn = '[cWDSInitialize]InitWDS'
    }

    cWDSInstallImage server2016
    {
        Ensure = 'Present'
        ImageName = 'Windows Server 2016 SERVERSTANDARD'
        GroupName = 'Windows Server 2016'
        Path = 'c:\wdsimages\install2016.wim'
        DependsOn = '[cWDSInitialize]InitWDS'
    }

    cWDSInstallImage server2012r2
    {
        Ensure = 'Present'
        ImageName = 'Windows Server 2012 R2 SERVERSTANDARD'
        GroupName = 'Windows Server 2012R2'
        Path = 'c:\wdsimages\install2012r2.wim'
        DependsOn = '[cWDSInitialize]InitWDS'
    }

    cWDSInstallImage windows10
    {
        Ensure = 'Present'
        ImageName = 'Windows 10 Enterprise Evaluation'
        GroupName = 'Windows 10'
        Path = 'c:\wdsimages\installw10_19h2.wim'
        DependsOn = '[cWDSInitialize]InitWDS'
    }
}

PullServerSQL
Start-DscConfiguration -Path .\PullServerSQL -Verbose -wait -Force
