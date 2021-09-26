# Configuration Data

@{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser = $true
 
            SourcePathSQL = '\\hyperdrive\public\sql\2017express'
            SourcePathXenAgent = '\\hyperdrive\public\agents\managementagentx64.msi'
        }
    )
    WimFiles = @(
        @{
            Name = 'Boot'
            SourcePath = "\\hyperdrive\public\wim\boot.wim"
            DestinationPath = 'c:\wdsimages\boot.wim'
            ImageName = 'Microsoft Windows Setup (x64)'
        },
        @{
            Name = 'Server2022'
            SourcePath = "\\hyperdrive\public\wim\install2022.wim"
            DestinationPath = 'c:\wdsimages\install2022.wim'
            ImageName = 'Windows Server 2022 SERVERSTANDARD'
            GroupName = 'Windows Server 2022'
            Unattendfile = 'install2022.xml'
        },
        @{
            Name = 'Server2019'
            SourcePath = "\\hyperdrive\public\wim\install2019.wim"
            DestinationPath = 'c:\wdsimages\install2019.wim'
            ImageName = 'Windows Server 2019 SERVERSTANDARD'
            GroupName = 'Windows Server 2019'
            Unattendfile = 'install2019.xml'
        },
        @{
            Name = 'Server2016'
            SourcePath = "\\hyperdrive\public\wim\install2016.wim"
            DestinationPath = 'c:\wdsimages\install2016.wim'
            ImageName = 'Windows Server 2016 SERVERSTANDARD'
            GroupName = 'Windows Server 2016'
            Unattendfile = 'install2016.xml'
        },
        @{
            Name = 'Server2012R2'
            SourcePath = "\\hyperdrive\public\wim\install2012r2.wim"
            DestinationPath = 'c:\wdsimages\install2012r2.wim'
            ImageName = 'Windows Server 2012 R2 SERVERSTANDARD'
            GroupName = 'Windows Server 2012R2'
            Unattendfile = 'install2012r2.xml'
        },
        ,
        @{
            Name = 'Windows10'
            SourcePath = "\\hyperdrive\public\wim\installw10_19h2.wim"
            DestinationPath = 'c:\wdsimages\installw10_19h2.wim'
            ImageName = 'Windows 10 Enterprise Evaluation'
            GroupName = 'Windows 10'
            Unattendfile = 'installwin10.xml'
        }
        ,
        @{
            Name = 'Windows11'
            SourcePath = "\\hyperdrive\public\wim\installw11.wim"
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
        },
        @{
            Name = 'ComputerManagementDsc'
        }
    )
 }