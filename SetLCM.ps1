Invoke-WebRequest -Uri https://github.com/JorgendG/BuildWDS/raw/master/DscPrivatePublicKey.pfx -OutFile C:\Windows\Temp\DscPrivatePublicKey.pfx

$mypwd = ConvertTo-SecureString -String "1234" -Force -AsPlainText
Import-PfxCertificate -FilePath C:\Windows\Temp\DscPrivatePublicKey.pfx -Password $mypwd -CertStoreLocation Cert:\LocalMachine\My


$regvalue = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Virtual Machine\Guest\Parameters" -Name "VirtualMachineName" -ErrorAction SilentlyContinue
$config = ($regvalue.VirtualMachineName -split ':')[1]
[dsclocalconfigurationmanager()]
configuration lcm {
    Settings {
        RefreshMode = 'Pull'
        RebootNodeIfNeeded = $true
        ConfigurationMode = 'ApplyAndAutoCorrect'
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

Get-LocalUser -Name "Administrator" | Enable-LocalUser

$newComputername = ($regvalue.VirtualMachineName -split ':')[0]
Rename-Computer -NewName $newComputername -Force


Set-DscLocalConfigurationManager c:\windows\temp -Verbose
