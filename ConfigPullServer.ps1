$sslcert = Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object { $_.Subject -eq 'CN=wds01' -and $_.Issuer -eq 'CN=wds01'  }
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

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc
    Import-DscResource -ModuleName NetworkingDsc
    Import-DscResource -ModuleName SqlServerDsc
    Import-DscResource -ModuleName cWDS
    
    node localhost
    {
        PendingReboot Reboot 
        {
            Name             = "Reboot"
            SkipCcmClientSDK = $true 
	    }

        File managementagentx64
        {
            Ensure = 'Present'
            Type = 'File'
            SourcePath = $Node.SourcePathXenAgent
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
            Arguments   = "/Lv c:\windows\temp\managementagentx64.log.txt /quiet /norestart"
            DependsOn   = '[File]managementagentx64'
        }

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

        File SQLServerFiles 
        {
            SourcePath = $Node.SourcePathSQL
            DestinationPath = 'c:\pullserver\sql'
            Ensure = 'Present'
            Type = 'Directory'
            Recurse = $true
        }

        
    
        SqlSetup SqlExpress
        {
            InstanceName           = 'SQLEXPRESS'
            Features               = 'SQLENGINE'
            SQLSysAdminAccounts    = 'BUILTIN\Administrators', 'NT AUTHORITY\SYSTEM'
            SourcePath             = 'c:\pullserver\sql'
            UpdateEnabled          = $false
            ForceReboot            = $false
            DependsOn              = '[WindowsFeature]NetFramework45','[File]SQLServerFiles'
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
            ConfigureFirewall            = $false
            SqlProvider                  = $true
            SqlConnectionString          = 'Provider=SQLOLEDB.1;Server=.\sqlexpress;Database=DemoDSC;Integrated Security=SSPI;Initial Catalog=master;'
            DependsOn                    = '[File]PullServerFiles', '[WindowsFeature]dscservice', '[SqlSetup]SqlExpress'
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

        Foreach($WimFile in $ConfigurationData.WimFiles)
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

        Foreach($DSCModule in $ConfigurationData.DSCModules)
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
 
$SharePwd = "P@ssword!" | ConvertTo-SecureString -AsPlainText -Force
$ShareUserName = "hyperdrive\readonly"
$ShareCredentials = New-Object System.Management.Automation.PSCredential -ArgumentList $ShareUserName, $SharePwd

  # Compile the LCM Config
 ConfigureLCM `
       -OutputPath . `
       -ConfigurationData ConfigPullServer.psd1
       
  # Apply the LCM Config
 Set-DscLocalConfigurationManager `
       -Path .\ConfigureLCM\ `
       -ComputerName Localhost `
       -Verbose

$sourcewim = '\\hyperdrive\public\wim'

PullServerSQL -ShareCredentials $ShareCredentials -ConfigurationData c:\Windows\Temp\ConfigPullServer.psd1
Start-DscConfiguration -Path .\PullServerSQL -Verbose -wait -Force
