
configuration HomelabConfig
{
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [PsCredential] $credential,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        [PsCredential] $ShareCredentials

    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'ComputerManagementDsc'
    Import-DscResource -ModuleName 'ActiveDirectoryDsc'
    Import-DscResource -ModuleName 'ActiveDirectoryCSDsc'
    Import-DscResource -ModuleName 'cWDS'
    Import-DscResource -ModuleName 'NetworkingDsc'
    Import-DscResource -ModuleName 'XenDesktop7'
    Import-DscResource -ModuleName 'SqlServerDsc'
    Import-DscResource -ModuleName 'xDnsServer'
    Import-DscResource -ModuleName 'xExchange' 

    Node 'subCA'
    {
        cVMName vmname {
            Ensure    = 'Present'
            DSCModule = 'Bla1'
        }

        DnsServerAddress setdns {
            Address        = $Node.IPDC01
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
        }

        PendingReboot herstart {
            Name             = "Herstart"
            SkipCcmClientSDK = $true 
        }

        Computer JoinDomain {
            Name       = 'localhost'
            DomainName = $Node.DomainName
            Credential = $Credential # Credential to join to domain
            DependsOn  = '[cVMName]vmname', '[DnsServerAddress]setdns'
        }

        File CAPolicy {
            Ensure          = 'Present'
            DestinationPath = 'C:\Windows\CAPolicy.inf'
            Contents        = "[Version]`r`n Signature= `"$Windows NT$`"`r`n[Certsrv_Server]`r`n RenewalKeyLength=2048`r`n RenewalValidityPeriod=Years`r`n RenewalValidityPeriodUnits=10`r`n LoadDefaultTemplates=1`r`n AlternateSignatureAlgorithm=1`r`n"
            Type            = 'File'
            DependsOn       = '[Computer]JoinDomain'
        }

        File CertEnrollFolder {
            Ensure          = 'Present'
            DestinationPath = 'C:\Windows\System32\CertSrv\CertEnroll'
            Type            = 'Directory'
            DependsOn       = '[File]CAPolicy'
        }

        xRemoteFile DownloadRootCACRTFile {
            DestinationPath = "C:\Windows\System32\CertSrv\CertEnroll\$($Node.RootCAName)_$($Node.RootCACommonName).crt"
            Uri             = "http://$($Node.RootCAName)/CertEnroll/$($Node.RootCAName)_$($Node.RootCACommonName).crt"
            DependsOn       = '[File]CertEnrollFolder'
        }
 
        # Download the Root CA certificate revocation list.
        xRemoteFile DownloadRootCACRLFile {
            DestinationPath = "C:\Windows\System32\CertSrv\CertEnroll\$($Node.RootCACommonName).crl"
            Uri             = "http://$($Node.RootCAName)/CertEnroll/$($Node.RootCACommonName).crl"
            DependsOn       = '[xRemoteFile]DownloadRootCACRTFile'
        }

        Script InstallRootCACert {
            PSDSCRunAsCredential = $Credential
            SetScript            = {
                Write-Verbose "Registering the Root CA Certificate C:\Windows\System32\CertSrv\CertEnroll\$($Using:Node.RootCAName)_$($Using:Node.RootCACommonName).crt in DS..."
                & "$($ENV:SystemRoot)\system32\certutil.exe" -f -dspublish "C:\Windows\System32\CertSrv\CertEnroll\$($Using:Node.RootCAName)_$($Using:Node.RootCACommonName).crt" RootCA
                Write-Verbose "Registering the Root CA CRL C:\Windows\System32\CertSrv\CertEnroll\$($Node.RootCACommonName).crl in DS..."
                & "$($ENV:SystemRoot)\system32\certutil.exe" -f -dspublish "C:\Windows\System32\CertSrv\CertEnroll\$($Node.RootCACommonName).crl" "$($Using:Node.RootCAName)"
                Write-Verbose "Installing the Root CA Certificate C:\Windows\System32\CertSrv\CertEnroll\$($Using:Node.RootCAName)_$($Using:Node.RootCACommonName).crt..."
                & "$($ENV:SystemRoot)\system32\certutil.exe" -addstore -f root "C:\Windows\System32\CertSrv\CertEnroll\$($Using:Node.RootCAName)_$($Using:Node.RootCACommonName).crt"
                Write-Verbose "Installing the Root CA CRL C:\Windows\System32\CertSrv\CertEnroll\$($Node.RootCACommonName).crl..."
                & "$($ENV:SystemRoot)\system32\certutil.exe" -addstore -f root "C:\Windows\System32\CertSrv\CertEnroll\$($Node.RootCACommonName).crl"
            }
            GetScript            = {
                Return @{
                    Installed = ((Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object -FilterScript { ($_.Subject -Like "CN=$($Using:Node.RootCACommonName),*") -and ($_.Issuer -Like "CN=$($Using:Node.RootCACommonName),*") } ).Count -EQ 0)
                }
            }
            TestScript           = { 
                If ((Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object -FilterScript { ($_.Subject -Like "CN=$($Using:Node.RootCACommonName),*") -and ($_.Issuer -Like "CN=$($Using:Node.RootCACommonName),*") } ).Count -EQ 0) {
                    Write-Verbose "Root CA Certificate Needs to be installed..."
                    Return $False
                }
                Return $True
            }
            DependsOn            = '[xRemoteFile]DownloadRootCACRTFile'
        }

        WindowsFeature ADCS-Cert-Authority {
            Ensure = 'Present'
            Name   = 'ADCS-Cert-Authority'
        }

        WindowsFeature RSAT-ADCS {
            Ensure               = 'Present'
            Name                 = 'RSAT-ADCS'
            IncludeAllSubFeature = $true
        }

        WindowsFeature WebEnrollmentCA {
            Name      = 'ADCS-Web-Enrollment'
            Ensure    = 'Present'
            DependsOn = "[WindowsFeature]ADCS-Cert-Authority"
        }

        ADCSCertificationAuthority ConfigCA {
            IsSingleInstance          = 'Yes'
            Ensure                    = 'Present'
            Credential                = $Credential
            CAType                    = 'EnterpriseSubordinateCA'
            CACommonName              = $Node.CACommonName
            CADistinguishedNameSuffix = $Node.CADistinguishedNameSuffix
            OverwriteExistingCAinDS   = $True
            OutputCertRequestFile     = "c:\windows\system32\certsrv\certenroll\$($Node.SubCAComputerName).req"
            DependsOn                 = '[Script]InstallRootCACert'
        }

        ADCSWebEnrollment ConfigWebEnrollment {
            IsSingleInstance = 'Yes'
            Ensure           = 'Present'
            #Name = 'ConfigWebEnrollment'
            Credential       = $Credential
            DependsOn        = '[ADCSCertificationAuthority]ConfigCA'
        }

        Script SetREQMimeType {
            SetScript  = {
                Add-WebConfigurationProperty -PSPath IIS:\ -Filter //staticContent -Name "." -Value @{fileExtension = '.req'; mimeType = 'application/pkcs10' }
            }
            GetScript  = {
                Return @{
                    'MimeType' = ((Get-WebConfigurationProperty -Filter "//staticContent/mimeMap[@fileExtension='.req']" -PSPath IIS:\ -Name *).mimeType);
                }
            }
            TestScript = { 
                If (-not (Get-WebConfigurationProperty -Filter "//staticContent/mimeMap[@fileExtension='.req']" -PSPath IIS:\ -Name *)) {
                    # Mime type is not set
                    Return $False
                }
                # Mime Type is already set
                Return $True
            }
            DependsOn  = '[ADCSWebEnrollment]ConfigWebEnrollment'
        }

        xRemoteFile DownloadSubCACERFile {
            DestinationPath = "C:\Windows\System32\CertSrv\CertEnroll\$($Node.SubCAComputerName)_$($Node.CACommonName).crt"
            Uri             = "http://$($Node.RootCAName)/CertEnroll/$($Node.SubCAComputerName).crt"
            DependsOn       = '[Script]SetREQMimeType'
        }

        Script RegisterSubCA {
            PSDSCRunAsCredential = $Credential
            SetScript            = {
                Write-Verbose "Registering the Sub CA Certificate with the Certification Authority C:\Windows\System32\CertSrv\CertEnroll\$($Using:env:COMPUTERNAME)_$($Using:Node.CACommonName).crt...."
                & "$($ENV:SystemRoot)\system32\certutil.exe" -installCert "C:\Windows\System32\CertSrv\CertEnroll\$($Using:env:COMPUTERNAME)_$($Using:Node.CACommonName).crt"
            }
            GetScript            = {
                Return @{
                }
            }
            TestScript           = { 
                If (-not (Get-ChildItem 'HKLM:\System\CurrentControlSet\Services\CertSvc\Configuration').GetValue('CACertHash')) {
                    Write-Verbose "Sub CA Certificate needs to be registered with the Certification Authority..."
                    Return $False
                }
                Return $True
            }
            DependsOn            = '[xRemoteFile]DownloadSubCACERFile'
        }

        Script ADCSAdvConfig {
            SetScript  = {
                If ($Using:Node.CADistinguishedNameSuffix) {
                    & "$($ENV:SystemRoot)\system32\certutil.exe" -setreg CA\DSConfigDN "CN=Configuration,$($Using:Node.CADistinguishedNameSuffix)"
                    & "$($ENV:SystemRoot)\system32\certutil.exe" -setreg CA\DSDomainDN "$($Using:Node.CADistinguishedNameSuffix)"
                }
                If ($Using:Node.CRLPublicationURLs) {
                    & "$($ENV:SystemRoot)\System32\certutil.exe" -setreg CA\CRLPublicationURLs $($Using:Node.CRLPublicationURLs)
                }
                If ($Using:Node.CACertPublicationURLs) {
                    & "$($ENV:SystemRoot)\System32\certutil.exe" -setreg CA\CACertPublicationURLs $($Using:Node.CACertPublicationURLs)
                }
                Restart-Service -Name CertSvc
                Add-Content -Path 'c:\windows\setup\scripts\certutil.log' -Value "Certificate Service Restarted ..."
            }
            GetScript  = {
                Return @{
                    'DSConfigDN'            = (Get-ChildItem 'HKLM:\System\CurrentControlSet\Services\CertSvc\Configuration').GetValue('DSConfigDN');
                    'DSDomainDN'            = (Get-ChildItem 'HKLM:\System\CurrentControlSet\Services\CertSvc\Configuration').GetValue('DSDomainDN');
                    'CRLPublicationURLs'    = (Get-ChildItem 'HKLM:\System\CurrentControlSet\Services\CertSvc\Configuration').GetValue('CRLPublicationURLs');
                    'CACertPublicationURLs' = (Get-ChildItem 'HKLM:\System\CurrentControlSet\Services\CertSvc\Configuration').GetValue('CACertPublicationURLs')
                }
            }
            TestScript = { 
                If (((Get-ChildItem 'HKLM:\System\CurrentControlSet\Services\CertSvc\Configuration').GetValue('DSConfigDN') -ne "CN=Configuration,$($Using:Node.CADistinguishedNameSuffix)")) {
                    Return $False
                }
                If (((Get-ChildItem 'HKLM:\System\CurrentControlSet\Services\CertSvc\Configuration').GetValue('DSDomainDN') -ne "$($Using:Node.CADistinguishedNameSuffix)")) {
                    Return $False
                }
                If (($Using:Node.CRLPublicationURLs) -and ((Get-ChildItem 'HKLM:\System\CurrentControlSet\Services\CertSvc\Configuration').GetValue('CRLPublicationURLs') -ne $Using:Node.CRLPublicationURLs)) {
                    Return $False
                }
                If (($Using:Node.CACertPublicationURLs) -and ((Get-ChildItem 'HKLM:\System\CurrentControlSet\Services\CertSvc\Configuration').GetValue('CACertPublicationURLs') -ne $Using:Node.CACertPublicationURLs)) {
                    Return $False
                }
                Return $True
            }
            DependsOn  = '[Script]RegisterSubCA'
        }
    }

    Node 'rootCA'
    {
        cVMName vmname {
            Ensure    = 'Present'
            DSCModule = 'Bla'
        }

        DnsServerAddress setdns {
            Address        = $Node.IPDC01
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
        }

        PendingReboot herstart {
            Name             = "Herstart"
            SkipCcmClientSDK = $true 
        }

        WindowsFeature ADCS-Cert-Authority {
            Ensure = 'Present'
            Name   = 'ADCS-Cert-Authority'
        }

        WindowsFeature ADCSWebEnrollment {
            Ensure    = 'Present'
            Name      = 'ADCS-Web-Enrollment'
            DependsOn = '[WindowsFeature]ADCS-Cert-Authority'
        }

        File CAPolicy {
            Ensure          = 'Present'
            DestinationPath = 'C:\Windows\CAPolicy.inf'
            Contents        = "[Version]`r`n Signature= `"$Windows NT$`"`r`n[Certsrv_Server]`r`n RenewalKeyLength=4096`r`n RenewalValidityPeriod=Years`r`n RenewalValidityPeriodUnits=20`r`n CRLDeltaPeriod=Days`r`n CRLDeltaPeriodUnits=0`r`n[CRLDistributionPoint]`r`n[AuthorityInformationAccess]`r`n"
            Type            = 'File'
            DependsOn       = '[WindowsFeature]ADCSWebEnrollment'
        }

        WindowsFeature RSAT-ADCS {
            Ensure               = 'Present'
            Name                 = 'RSAT-ADCS'
            IncludeAllSubFeature = $true
        }

        AdcsCertificationAuthority CertificateAuthority {
            IsSingleInstance          = 'Yes'
            Ensure                    = 'Present'
            Credential                = $Credential
            CAType                    = 'StandaloneRootCA'
            CACommonName              = $Node.CACommonName
            CADistinguishedNameSuffix = $Node.CADistinguishedNameSuffix
            ValidityPeriod            = 'Years'
            ValidityPeriodUnits       = 20
            DependsOn                 = '[File]CAPolicy'
        }

        ADCSWebEnrollment ConfigWebEnrollment {
            IsSingleInstance = 'Yes'
            Ensure           = 'Present'
            #Name = 'ConfigWebEnrollment'
            Credential       = $Credential
            DependsOn        = '[ADCSCertificationAuthority]CertificateAuthority'
        }

        Script ADCSAdvConfig {
            SetScript  = {
                If ($Using:Node.CADistinguishedNameSuffix) {
                    & "$($ENV:SystemRoot)\system32\certutil.exe" -setreg CA\DSConfigDN "CN=Configuration,$($Using:Node.CADistinguishedNameSuffix)"
                    & "$($ENV:SystemRoot)\system32\certutil.exe" -setreg CA\DSDomainDN "$($Using:Node.CADistinguishedNameSuffix)"
                }
                If ($Using:Node.CRLPublicationURLs) {
                    & "$($ENV:SystemRoot)\System32\certutil.exe" -setreg CA\CRLPublicationURLs $($Using:Node.CRLPublicationURLs)
                }
                If ($Using:Node.CACertPublicationURLs) {
                    & "$($ENV:SystemRoot)\System32\certutil.exe" -setreg CA\CACertPublicationURLs $($Using:Node.CACertPublicationURLs)
                }
                If ($Using:Node.CRLPeriodUnits) {
                    & "$($ENV:SystemRoot)\System32\certutil.exe" -setreg CA\CRLPeriodUnits $($Using:Node.CRLPeriodUnits)
                    & "$($ENV:SystemRoot)\System32\certutil.exe" -setreg CA\CRLPeriod 'Months'
                }
                & "$($ENV:SystemRoot)\System32\certutil.exe" -setreg CA\CRLOverlapPeriodUnits 12
                & "$($ENV:SystemRoot)\System32\certutil.exe" -setreg CA\CRLOverlapPeriod "Hours"
                & "$($ENV:SystemRoot)\System32\certutil.exe" -setreg CA\ValidityPeriodUnits 10
                & "$($ENV:SystemRoot)\System32\certutil.exe" -setreg CA\ValidityPeriod "Years"
                Restart-Service -Name CertSvc
                Add-Content -Path 'c:\windows\setup\scripts\certutil.log' -Value "Certificate Service Restarted ..."
            }
            GetScript  = {
                Return @{
                    'DSConfigDN'            = (Get-ChildItem 'HKLM:\System\CurrentControlSet\Services\CertSvc\Configuration').GetValue('DSConfigDN')
                    'DSDomainDN'            = (Get-ChildItem 'HKLM:\System\CurrentControlSet\Services\CertSvc\Configuration').GetValue('DSDomainDN')
                    'CRLPublicationURLs'    = (Get-ChildItem 'HKLM:\System\CurrentControlSet\Services\CertSvc\Configuration').GetValue('CRLPublicationURLs');
                    'CACertPublicationURLs' = (Get-ChildItem 'HKLM:\System\CurrentControlSet\Services\CertSvc\Configuration').GetValue('CACertPublicationURLs')
                    'CRLPeriodUnits'        = (Get-ChildItem 'HKLM:\System\CurrentControlSet\Services\CertSvc\Configuration').GetValue('CRLPeriodUnits')
                }
            }
            TestScript = { 
                If (((Get-ChildItem 'HKLM:\System\CurrentControlSet\Services\CertSvc\Configuration').GetValue('DSConfigDN') -ne "CN=Configuration,$($Using:Node.CADistinguishedNameSuffix)")) {
                    Return $False
                }
                If (((Get-ChildItem 'HKLM:\System\CurrentControlSet\Services\CertSvc\Configuration').GetValue('DSDomainDN') -ne "$($Using:Node.CADistinguishedNameSuffix)")) {
                    Return $False
                }
                If (($Using:Node.CRLPublicationURLs) -and ((Get-ChildItem 'HKLM:\System\CurrentControlSet\Services\CertSvc\Configuration').GetValue('CRLPublicationURLs') -ne $Using:Node.CRLPublicationURLs)) {
                    Return $False
                }
                If (($Using:Node.CACertPublicationURLs) -and ((Get-ChildItem 'HKLM:\System\CurrentControlSet\Services\CertSvc\Configuration').GetValue('CACertPublicationURLs') -ne $Using:Node.CACertPublicationURLs)) {
                    Return $False
                }
                If (($Using:Node.CRLPeriodUnits) -and ((Get-ChildItem 'HKLM:\System\CurrentControlSet\Services\CertSvc\Configuration').GetValue('CRLPeriodUnits') -ne $Using:Node.CRLPeriodUnits)) {
                    Return $False
                }
                Return $True
            }
            DependsOn  = '[ADCSWebEnrollment]ConfigWebEnrollment'
        }

        Foreach ($SubCA in $Node.SubCAs) {
            xRemoteFile "DownloadSubCA_$SubCA" {
                DestinationPath = "C:\Windows\System32\CertSrv\CertEnroll\$SubCA.req"
                Uri             = "http://$SubCA/CertEnroll/$SubCA.req"
                DependsOn       = "[Script]ADCSAdvConfig"
            }
            Script "IssueCert_$SubCA" {
                SetScript  = {
                    Write-Verbose "Submitting C:\Windows\System32\CertSrv\CertEnroll\$Using:SubCA.req to $($Using:Node.CACommonName)"
                    [String]$RequestResult = & "$($ENV:SystemRoot)\System32\Certreq.exe" -Config ".\$($Using:Node.CACommonName)" -Submit "C:\Windows\System32\CertSrv\CertEnroll\$Using:SubCA.req"
                    $MatchesReqs = [Regex]::Match($RequestResult, 'RequestId:\s([0-9]*)')
                    If ($MatchesReqs.Groups.Count -lt 2) {
                        Write-Verbose "Error getting Request ID from SubCA certificate submission."
                        Throw "Error getting Request ID from SubCA certificate submission."
                    }
                    [int]$RequestId = $MatchesReqs.Groups[1].Value
                    Write-Verbose "Issuing $RequestId in $($Using:Node.CACommonName)"
                    [String]$SubmitResult = & "$($ENV:SystemRoot)\System32\CertUtil.exe" -Resubmit $RequestId
                    If ($SubmitResult -notlike 'Certificate issued.*') {
                        Write-Verbose "Unexpected result issuing SubCA request."
                        Throw "Unexpected result issuing SubCA request."
                    }
                    Write-Verbose "Retrieving C:\Windows\System32\CertSrv\CertEnroll\$Using:SubCA.req from $($Using:Node.CACommonName)"
                    & "$($ENV:SystemRoot)\System32\Certreq.exe" -Config ".\$($Using:Node.CACommonName)" -Retrieve $RequestId "C:\Windows\System32\CertSrv\CertEnroll\$Using:SubCA.crt"
                }
                GetScript  = {
                    Return @{
                        'Generated' = (Test-Path -Path "C:\Windows\System32\CertSrv\CertEnroll\$Using:SubCA.crt");
                    }
                }
                TestScript = { 
                    If (-not (Test-Path -Path "C:\Windows\System32\CertSrv\CertEnroll\$Using:SubCA.crt")) {
                        # SubCA Cert is not yet created
                        Return $False
                    }
                    # SubCA Cert has been created
                    Return $True
                }
                DependsOn  = "[xRemoteFile]DownloadSubCA_$SubCA"
            }
        }
    }

    Node 'Member'
    {
        cVMName vmname {
            Ensure    = 'Present'
            DSCModule = 'Bla'
        }

        PendingReboot herstart {
            Name             = "Herstart"
            SkipCcmClientSDK = $true 
        }

        DnsServerAddress setdns {
            Address        = $Node.IPDC01
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
        }

        Computer JoinDomain {
            Name       = 'localhost'
            DomainName = $Node.DomainName
            Credential = $Credential # Credential to join to domain
            DependsOn  = '[cVMName]vmname', '[DnsServerAddress]setdns'
        }
    }

    Node 'XDDC'
    {
        cVMName vmname {
            Ensure    = 'Present'
            DSCModule = 'Bla'
        }

        PendingReboot herstart {
            Name             = "Herstart"
            SkipCcmClientSDK = $true 
        }

        DnsServerAddress setdns {
            Address        = $Node.IPDC01
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
        }

        Computer JoinDomain {
            Name       = 'localhost'
            DomainName = $Node.DomainName
            Credential = $Credential # Credential to join to domain
            DependsOn  = '[cVMName]vmname', '[DnsServerAddress]setdns'
        }

        WindowsFeature 'NetFramework45' {
            Name      = 'NET-Framework-45-Core'
            Ensure    = 'Present'
            DependsOn = '[Computer]JoinDomain'
        }

        SqlSetup SqlExpress {
            InstanceName        = 'SQLEXPRESS'
            Features            = 'SQLENGINE'
            SQLSysAdminAccounts = 'BUILTIN\Administrators', 'NT AUTHORITY\SYSTEM'
            SourcePath          = $sourcesql
            SourceCredential    = $ShareCredentials
            UpdateEnabled       = 'False'
            ForceReboot         = $false
            DependsOn           = '[WindowsFeature]NetFramework45'
        }

        File installfolder {
            Ensure          = 'Present'
            DestinationPath = 'c:\install'
            Type            = 'Directory'
        }

        File xdfiles {
            Ensure          = 'Present'
            SourcePath      = $node.SourceXD
            Credential      = $ShareCredentials
            DestinationPath = 'c:\install\xd7'
            Recurse         = $true
            MatchSource     = $false
            DependsOn       = '[File]installfolder'
        }

        XD7Features XD7Controller {
            Role             = 'Controller', 'Director', 'Licensing', 'Storefront', 'Studio'
            SourcePath       = 'c:\install\xd7'
            IsSingleInstance = 'Yes'
            DependsOn        = '[Computer]JoinDomain', '[File]xdfiles'
        }

        XD7Database 'XD7SiteDatabase' {
            SiteName       = 'Homelab Site' 
            DatabaseServer = 'XDDC01\SQLEXPRESS'
            DatabaseName   = 'SiteDB'
            DataStore      = 'Site'
            DependsOn      = '[XD7Features]XD7Controller'
        }

        XD7Database 'XD7SiteLoggingDatabase' {
            SiteName       = 'Homelab Site'
            DatabaseServer = 'XDDC01\SQLEXPRESS'
            DatabaseName   = 'LogDB'
            DataStore      = 'Logging';
            DependsOn      = '[XD7Features]XD7Controller';
        }

        XD7Database 'XD7SiteMonitorDatabase' {
            SiteName       = 'Homelab Site'
            DatabaseServer = 'XDDC01\SQLEXPRESS'
            DatabaseName   = 'MonDB'
            DataStore      = 'Monitor';
            DependsOn      = '[XD7Features]XD7Controller';
        }

        XD7Site 'XD7Site' {
            SiteName            = 'Homelab Site'
            DatabaseServer      = 'XDDC01\SQLEXPRESS'
            SiteDatabaseName    = 'SiteDB'
            LoggingDatabaseName = 'LogDB'
            MonitorDatabaseName = 'MonDB'
            DependsOn           = '[XD7Features]XD7Controller', '[XD7Database]XD7SiteDatabase', '[XD7Database]XD7SiteLoggingDatabase', '[XD7Database]XD7SiteMonitorDatabase';
        }

        XD7Administrator XD7AdministratorExample {
            Name      = 'Domain Admins'
            Enabled   = $true
            Ensure    = 'Present'
            DependsOn = '[xd7site]XD7Site'
        }

        XD7Administrator XD7Administrator {
            Name      = 'Administrator'
            Enabled   = $true
            Ensure    = 'Present'
            DependsOn = '[xd7site]XD7Site'
        }

        XD7Administrator XD7AdministratorHomelab {
            Name      = 'homelab\Administrator'
            Enabled   = $true
            Ensure    = 'Present'
            DependsOn = '[xd7site]XD7Site'
        }
    }

    Node 'Web'
    {
        cVMName vmname {
            Ensure    = 'Present'
            DSCModule = 'Bla'
        }

        PendingReboot herstart {
            Name             = "Herstart"
            SkipCcmClientSDK = $true 
        }
        
        WindowsFeature InstallWebServer {
            Name   = "Web-Server"
            Ensure = "Present"
        }

        WindowsFeature InstallAspNet45 {
            Name   = "Web-Asp-Net45"
            Ensure = "Present"
        }
        
        WindowsFeature Web-Mgmt-Console {
            Name   = "Web-Mgmt-Console"
            Ensure = "Present"
        }

        DnsServerAddress setdns {
            Address        = $Node.IPDC01
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
        }

        Computer JoinDomain {
            Name       = 'localhost'
            DomainName = $Node.DomainName
            Credential = $Credential # Credential to join to domain
            DependsOn  = '[cVMName]vmname', '[DnsServerAddress]setdns'
        }

        Firewall iis {
            Name    = 'IIS-WebServerRole-HTTP-In-TCP'
            Ensure  = 'Present'
            Enabled = 'True'
        }
    }

    Node 'DC'
    {
        PendingReboot herstart {
            Name             = "Herstart"
            SkipCcmClientSDK = $true 
        }

        cVMName vmname {
            Ensure    = 'Present'
            DSCModule = 'Bla'
        }

        File ADFiles {
            Ensure          = 'Present'
            DestinationPath = "C:\NTDS"
            Type            = 'Directory'
        }

        NetIPInterface DisableDhcp {
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
            Dhcp           = 'Disabled'
        }

        IPAddress ipDC {
            #$ConfigData.AllNodes[0].DomainName
            IPAddress      = "$($Node.IPDC01)" + "/24"
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
            DependsOn      = '[NetIPInterface]DisableDhcp'
        }
        
        DefaultGatewayAddress SetDefaultGateway {
            Address        = '192.168.1.1'
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
            DependsOn      = '[NetIPInterface]DisableDhcp'
        }

        WindowsFeature ADDSInstall {             
            Ensure = "Present"             
            Name   = "AD-Domain-Services"             
        }            
            
        WindowsFeature ADDSTools {             
            Ensure = "Present"             
            Name   = "RSAT-ADDS"             
        }     

        ADDomain ConfigDC {             
            DomainName                    = $Node.DomainName
            Credential                    = $Credential
            SafemodeAdministratorPassword = $Credential
            DatabasePath                  = 'c:\NTDS'            
            LogPath                       = 'c:\NTDS'            
            DependsOn                     = "[WindowsFeature]ADDSInstall", "[File]ADFiles", "[IPAddress]ipDC" , '[cVMName]vmname'         
        }

        xDnsServerForwarder forward8888 {
            IPAddresses      = '8.8.8.8'
            IsSingleInstance = 'Yes'
            DependsOn        = '[ADDomain]ConfigDC'
        }

        Foreach ($DNSRecord in $ConfigurationData.DNSRecords) {
            DnsRecordA "DNSRecord-$($DNSRecord.Name)" {
                Ensure      = 'Present'
                Name        = $DNSRecord.Name
                IPv4Address = $DNSRecord.IPNumber
                ZoneName    = $Node.DomainName
            }
        }
    }

    Node 'DC22'
    {
        PendingReboot herstart {
            Name             = "Herstart"
            SkipCcmClientSDK = $true 
        }

        cVMName vmname {
            Ensure    = 'Present'
            DSCModule = 'Bla'
        }

        File ADFiles {
            Ensure          = 'Present'
            DestinationPath = "C:\NTDS"
            Type            = 'Directory'
        }

        NetIPInterface DisableDhcp {
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
            Dhcp           = 'Disabled'
        }

        IPAddress ipDC23 {
            #$ConfigData.AllNodes[0].DomainName
            IPAddress      = "$($Node.IPDC01)" + "/24"
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
            DependsOn      = '[NetIPInterface]DisableDhcp'
        }
        
        DefaultGatewayAddress SetDefaultGateway {
            Address        = '192.168.1.1'
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
            DependsOn      = '[NetIPInterface]DisableDhcp'
        }

        DnsServerAddress setdns {
            Address        = $Node.IPDC02
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
        }

        WindowsFeature ADDSInstall {             
            Ensure = "Present"             
            Name   = "AD-Domain-Services"             
        }            
            
        WindowsFeature ADDSTools {             
            Ensure = "Present"             
            Name   = "RSAT-ADDS"             
        }

        WaitForADDomain 'WaitForestAvailability' {
            DomainName = $Node.DomainName
            Credential = $Credential

            DependsOn  = '[WindowsFeature]ADDSTools'
        }

        ADDomainController 'DomainControllerMinimal' {
            DomainName                    = $Node.DomainName
            Credential                    = $Credential
            SafeModeAdministratorPassword = $Credential

            DependsOn                     = '[WaitForADDomain]WaitForestAvailability', "[WindowsFeature]ADDSInstall", "[File]ADFiles", "[IPAddress]ipDC23" , '[cVMName]vmname'
        }

        Foreach ($DNSRecord in $ConfigurationData.DNSRecords) {
            DnsRecordA "DNSRecord-$($DNSRecord.Name)" {
                Ensure      = 'Present'
                Name        = $DNSRecord.Name
                IPv4Address = $DNSRecord.IPNumber
                ZoneName    = $Node.DomainName
            }
        }

        
    }

    Node 'DC23'
    {
        PendingReboot herstart {
            Name             = "Herstart"
            SkipCcmClientSDK = $true 
        }

        cVMName vmname {
            Ensure    = 'Present'
            DSCModule = 'Bla'
        }

        File ADFiles {
            Ensure          = 'Present'
            DestinationPath = "C:\NTDS"
            Type            = 'Directory'
        }

        NetIPInterface DisableDhcp {
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
            Dhcp           = 'Disabled'
        }

        IPAddress ipDC23 {
            #$ConfigData.AllNodes[0].DomainName
            IPAddress      = "$($Node.IPDC02)" + "/24"
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
            DependsOn      = '[NetIPInterface]DisableDhcp'
        }
        
        DefaultGatewayAddress SetDefaultGateway {
            Address        = '192.168.1.1'
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
            DependsOn      = '[NetIPInterface]DisableDhcp'
        }

        DnsServerAddress setdns {
            Address        = $Node.IPDC01
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
        }

        WindowsFeature ADDSInstall {             
            Ensure = "Present"             
            Name   = "AD-Domain-Services"             
        }            
            
        WindowsFeature ADDSTools {             
            Ensure = "Present"             
            Name   = "RSAT-ADDS"             
        }

        WaitForADDomain 'WaitForestAvailability' {
            DomainName = $Node.DomainName
            Credential = $Credential

            DependsOn  = '[WindowsFeature]ADDSTools'
        }

        ADDomainController 'DomainControllerMinimal' {
            DomainName                    = $Node.DomainName
            Credential                    = $Credential
            SafeModeAdministratorPassword = $Credential

            DependsOn                     = '[WaitForADDomain]WaitForestAvailability', "[WindowsFeature]ADDSInstall", "[File]ADFiles", "[IPAddress]ipDC23" , '[cVMName]vmname'
        }

        
    }
    
    Node 'Docker'
    {
        cVMName vmname {
            Ensure    = 'Present'
            DSCModule = 'Bla'
        }

        PendingReboot herstart {
            Name             = "Herstart"
            SkipCcmClientSDK = $true 
        }

        DnsServerAddress setdns {
            Address        = $Node.IPDC01
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
        }

        Computer JoinDomain {
            Name       = 'localhost'
            DomainName = $Node.DomainName
            Credential = $Credential
            DependsOn  = '[cVMName]vmname', '[DnsServerAddress]setdns'
        }

        WindowsFeature InstallHyper-V-PowerShell {
            Name   = "Hyper-V-PowerShell"
            Ensure = "Present"
        }

        WindowsFeature InstallContainers {
            Name   = "Containers"
            Ensure = "Present"
        }
    }

    Node 'Syslog'
    {
        cVMName vmname {
            Ensure    = 'Present'
            DSCModule = 'Bla'
        }

        PendingReboot herstart {
            Name             = "Herstart"
            SkipCcmClientSDK = $true 
        }

        DnsServerAddress setdns {
            Address        = $Node.IPDC01
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
        }

        Computer JoinDomain {
            Name       = 'localhost'
            DomainName = $Node.DomainName
            Credential = $Credential
            DependsOn  = '[cVMName]vmname', '[DnsServerAddress]setdns'
        }

        WindowsFeature Framework3 {
            Name   = "NET-Framework-Core"
            Ensure = "Present"
            Source = $Node.SourceNET3
        }

        File vcredist_x86_2010 {
            Ensure          = 'Present'
            Type            = 'File'
            SourcePath      = $Node.SourceVCx862010
            DestinationPath = 'c:\Windows\temp\SourceVCx862010.exe'
            Credential      = $ShareCredentials
            MatchSource     = $false
        }

        Package SourceVCx862010 {
            Ensure    = "Present"
            Name      = "Microsoft Visual C++ 2010  x86 Redistributable - 10.0.30319"
            Path      = 'c:\Windows\temp\SourceVCx862010.exe'
            ProductId = ''
            Arguments = "/q"
            LogPath   = "C:\windows\temp\SourceVCx862010.log"
            DependsOn = '[File]vcredist_x86_2010'
        }

        File vcredist_x86_2013 {
            Ensure          = 'Present'
            Type            = 'File'
            SourcePath      = $Node.SourceVCx862013
            DestinationPath = 'c:\Windows\temp\SourceVCx862013.exe'
            Credential      = $ShareCredentials
            MatchSource     = $false
        }

        Package SourceVCx862013 {
            Ensure    = "Present"
            Name      = "Microsoft Visual C++ 2013 x86 Minimum Runtime - 12.0.21005"
            Path      = 'c:\Windows\temp\SourceVCx862013.exe'
            ProductId = ''
            Arguments = "/q"
            LogPath   = "C:\windows\temp\SourceVCx862013.log"
            DependsOn = '[File]vcredist_x86_2013'
        }

        File KiwiSetupfile {
            Ensure          = 'Present'
            Type            = 'File'
            SourcePath      = $Node.SourceKiwi
            DestinationPath = 'c:\Windows\temp\Kiwisetup.exe'
            Credential      = $ShareCredentials
            MatchSource     = $false
        }

        Package Kiwisetup {
            Ensure    = "Present"
            Name      = "Kiwi Syslog Server 9.7.2  (Service Edition)"
            Path      = 'c:\Windows\temp\Kiwisetup.exe'
            ProductId = ''
            Arguments = "/S INSTALL=SERVICE"
            LogPath   = "C:\windows\temp\Kiwisetup.log"
            DependsOn = '[File]KiwiSetupfile'
        }
    }

    Node 'Exchange'
    {
        cVMName vmname {
            Ensure    = 'Present'
            DSCModule = 'Bla'
        }

        PendingReboot herstart {
            Name             = "Herstart"
            SkipCcmClientSDK = $true 
        }

        DnsServerAddress setdns {
            Address        = $Node.IPDC01
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
        }

        Computer JoinDomain {
            Name       = 'localhost'
            DomainName = $Node.DomainName
            Credential = $Credential
            DependsOn  = '[cVMName]vmname', '[DnsServerAddress]setdns'
        }

        File ExchangeBinaries {
            Ensure          = 'Present'
            Type            = 'Directory'
            Recurse         = $true
            SourcePath      = $Node.ExchangeSource
            DestinationPath = 'C:\Binaries\E15CU6'
            Credential      = $ShareCredentials
            MatchSource     = $false
        }
    }
}

if ( (Test-Path -Path c:\Windows\Temp\credpwd.txt) -and (Test-Path -Path c:\Windows\Temp\credusr.txt) ) {
    $credpwd = Get-Content c:\Windows\Temp\credpwd.txt | ConvertTo-SecureString
    $usr = Get-Content c:\Windows\Temp\credusr.txt
    $credential = New-Object System.Management.Automation.PsCredential($usr, $credpwd)
}
else {
    $credential = Get-Credential -Message "Domain credentials" -UserName 'homelabdc22\administrator'
    $credential.UserName | Set-Content c:\Windows\Temp\credusr.txt -Force
    $credential.Password | ConvertFrom-SecureString | Set-Content c:\Windows\Temp\credpwd.txt -force
}

$SharePwd = "P@ssword!" | ConvertTo-SecureString -AsPlainText -Force
$ShareUserName = "hyperdrive\readonly"
$ShareCredentials = New-Object System.Management.Automation.PSCredential -ArgumentList $ShareUserName, $SharePwd

$mofs = HomelabConfig -credential $credential -ShareCredentials $ShareCredentials -ConfigurationData .\MakeDSCConfig.psd1

foreach ($configMof in $Mofs) {
    $dest = "C:\pullserver\Configuration\$($configmof.name)"
    Copy-Item $configMof.FullName $dest
    New-DSCChecksum $dest -Force
}