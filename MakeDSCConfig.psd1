@{
    AllNodes = @(
        @{
            NodeName = "*"
            CertificateFile = "C:\Pullserver\DscPublicKey.cer"
            Thumbprint = "05DAA37D7A0013E346DC0FD0350DA79C3193A4AB"
            PSDscAllowDomainUser = $true
            DomainName = "homelabdc22.local"
            IPDC01 = "192.168.1.22"
            sourcesql = '\\hyperdrive\public\sql\2017express'

        },
        @{
            NodeName = "subCA"
            PSDscAllowDomainUser = $true
            CACommonName = "Homelab Issuing CA"
            CADistinguishedNameSuffix = "DC=homelabdc22,DC=local"
            CRLPublicationURLs = "65:C:\Windows\system32\CertSrv\CertEnroll\%3%8%9.crl\n79:ldap:///CN=%7%8,CN=%2,CN=CDP,CN=Public Key Services,CN=Services,%6%10\n6:http://pki.homelabdc22.local/CertEnroll/%3%8%9.crl"
            CACertPublicationURLs = "1:C:\Windows\system32\CertSrv\CertEnroll\%1_%3%4.crt\n2:ldap:///CN=%7,CN=AIA,CN=Public Key Services,CN=Services,%6%11\n2:http://pki.homelabdc22.local/CertEnroll/%1_%3%4.crt"
            RootCAName = "rootCA"
            RootCACRTName = "rootCA_Homelab Root CA.crt"
            RootCACommonName = 'Homelab Root CA'
            SubCAComputerName = "CA02" 
        }
        ,
        @{
            NodeName = "rootCA"
            PSDscAllowDomainUser = $true
            CACommonName = 'Homelab Root CA'
            CADistinguishedNameSuffix = "DC=homelabdc22,DC=local"
            CRLPublicationURLs = "1:C:\Windows\system32\CertSrv\CertEnroll\%3%8%9.crl\n10:ldap:///CN=%7%8,CN=%2,CN=CDP,CN=Public Key Services,CN=Services,%6%10\n2:http://pki.homelabdc22.local/CertEnroll/%3%8%9.crl"
            CACertPublicationURLs = "1:C:\Windows\system32\CertSrv\CertEnroll\%1_%3%4.crt\n2:ldap:///CN=%7,CN=AIA,CN=Public Key Services,CN=Services,%6%11\n2:http://pki.homelabdc22.local/CertEnroll/%1_%3%4.crt"
            CRLPeriodUnits = 12
            SubCAs = @('CA02')
        }
        ,
        @{
            NodeName = "DC"
            PSDscAllowDomainUser = $true
        }
        ,
        @{
            NodeName = "Member"
            PSDscAllowDomainUser = $true
        }
        ,
        @{
            NodeName = "Web"
            PSDscAllowDomainUser = $true
        }
        ,
        @{
            NodeName = "XDDC"
            PSDscAllowDomainUser = $true
            SourceXD = '\\hyperdrive\public\xendesktop\1912'
        }
        ,
        @{
            NodeName = "Docker"
            PSDscAllowDomainUser = $true
        }
        ,
        @{
            NodeName = "Syslog"
            PSDscAllowDomainUser = $true
            SourceNET3 = '\\hyperdrive\public\sxs\2016\sxs'
            # vcredist_x86_2010
            SourceVCx862010 = '\\hyperdrive\public\syslog\vcredist_x86_2010.exe'
            SourceVCx862013 = '\\hyperdrive\public\syslog\vcredist_x86_2013.exe'
            SourceKiwi = '\\hyperdrive\public\syslog\Kiwi_Syslog_Server_9.7.2.Eval.setup.exe'
        }

    )

    DomainData = @(
        @{
            DomainName = "homelabdc22.local"
            DCIpNumber = "192.168.1.22"
        }
    )
    
    DNSRecords = @(
        @{
            Name = 'ns30'
            IPNumber = '192.168.1.30'
        },
        @{
            Name = 'ns31'
            IPNumber = '192.168.1.31'
        },
        @{
            Name = 'ns40'
            IPNumber = '192.168.1.40'
        },
        @{
            Name = 'ns41'
            IPNumber = '192.168.1.41'
        },
        @{
            Name = 'adm01'
            IPNumber = '192.168.1.29'
        },
        @{
            Name = 'webtest'
            IPNumber = '192.168.1.44'
        },
        @{
            Name = 'pfsense'
            IPNumber = '192.168.1.7'
        },
        @{
            Name = 'wordpress'
            IPNumber = '192.168.1.70'
        },
        @{
            Name = 'portainer'
            IPNumber = '192.168.1.71'
        },
        @{
            Name = 'mediawiki'
            IPNumber = '192.168.1.72'
        }
    )
}
