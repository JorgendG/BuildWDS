Get-LocalUser -Name "Administrator" | Enable-LocalUser

# certificaat tbv credential encryptie
Invoke-WebRequest -Uri http://wds01/DscPrivatePublicKey.pfx.txt -OutFile C:\Windows\Temp\DscPrivatePublicKey.pfx
$pfxpwd = ConvertTo-SecureString -String "1234" -Force -AsPlainText
$pfx = Import-PfxCertificate -FilePath C:\Windows\Temp\DscPrivatePublicKey.pfx -Password $pfxpwd -CertStoreLocation Cert:\LocalMachine\My

Invoke-WebRequest -Uri http://wds01/wds01.cer.txt -OutFile C:\Windows\Temp\wds01.cer
Import-Certificate -FilePath C:\Windows\Temp\wds01.cer -CertStoreLocation Cert:\LocalMachine\Root

# vm is computername:config:osversion
$regvalue = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Virtual Machine\Guest\Parameters" -Name "VirtualMachineName" -ErrorAction SilentlyContinue
$config = ($regvalue.VirtualMachineName -split ':')[1]
[dsclocalconfigurationmanager()]
configuration lcm {
    Settings {
        RefreshMode = 'Pull'
        RefreshFrequencyMins = 30
        RebootNodeIfNeeded = $true
        ConfigurationMode = 'ApplyAndAutoCorrect'
        CertificateID = $pfx.Thumbprint
    }

    ConfigurationRepositoryWeb SQLPullWeb {
        ServerURL = 'https://wds01:8080/PSDSCPullServer.svc'
        RegistrationKey = 'cb30127b-4b66-4f83-b207-c4801fb05087'
        ConfigurationNames = @("$config")
        AllowUnsecureConnection = $false
    }

    ReportServerWeb SQLPullWeb {
        ServerURL = 'https://wds01:8080/PSDSCPullServer.svc'
        RegistrationKey = 'cb30127b-4b66-4f83-b207-c4801fb05087'
        AllowUnsecureConnection = $false
    }
}

lcm -OutputPath C:\Windows\temp

Set-Service -Name winrm -StartupType Automatic
Start-Service winrm
Set-DscLocalConfigurationManager c:\windows\temp -Verbose
Update-DscConfiguration
