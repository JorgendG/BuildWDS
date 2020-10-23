Get-LocalUser -Name "Administrator" | Enable-LocalUser

# certificaat tbv credential encryptie
Invoke-WebRequest -Uri https://github.com/JorgendG/BuildWDS/raw/master/DscPrivatePublicKey.pfx -OutFile C:\Windows\Temp\DscPrivatePublicKey.pfx
$mypwd = ConvertTo-SecureString -String "1234" -Force -AsPlainText
Import-PfxCertificate -FilePath C:\Windows\Temp\DscPrivatePublicKey.pfx -Password $mypwd -CertStoreLocation Cert:\LocalMachine\My

Invoke-WebRequest -Uri http://wds01/wds01.cer.txt -OutFile C:\Windows\Temp\wds01.cer
Import-Certificate -FilePath C:\Windows\Temp\wds01.cer -CertStoreLocation Cert:\LocalMachine\Root

$regvalue = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Virtual Machine\Guest\Parameters" -Name "VirtualMachineName" -ErrorAction SilentlyContinue
$config = ($regvalue.VirtualMachineName -split ':')[1]
[dsclocalconfigurationmanager()]
configuration lcm {
    Settings {
        RefreshMode = 'Pull'
        RebootNodeIfNeeded = $true
        ConfigurationMode = 'ApplyAndAutoCorrect'
        CertificateID = '05daa37d7a0013e346dc0fd0350da79c3193a4ab'
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



$newComputername = ($regvalue.VirtualMachineName -split ':')[0]
Rename-Computer -NewName $newComputername -Force

sc config winrm start= auto
Start-Service winrm
Set-DscLocalConfigurationManager c:\windows\temp -Verbose
