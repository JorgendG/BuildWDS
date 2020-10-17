$ConfigData= @{
    AllNodes = @(
            @{
                NodeName = "*"
                CertificateFile = "C:\windows\temp\DscPublicKey.cer"
                Thumbprint = "05DAA37D7A0013E346DC0FD0350DA79C3193A4AB"
                PSDscAllowDomainUser = $true
            },
            @{
                NodeName = "CA"
                PSDscAllowDomainUser = $true
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

        )
    }


configuration CredentialEncryptionExample
{
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PsCredential] $credential
    )

    Import-DscResource –ModuleName 'PSDesiredStateConfiguration' 

    Node 'CA'
    {
        File exampleFile
        {
            SourcePath = "\\WIN-U20DTKMF9RA\c$\share\test.txt"
            DestinationPath = "C:\testCA.txt"
            Credential = $credential
        }
    }

    Node 'Member'
    {
        File exampleFile
        {
            SourcePath = "\\WIN-U20DTKMF9RA\c$\share\test.txt"
            DestinationPath = "C:\testMember.txt"
            Credential = $credential
        }
    }

    Node 'DC'
    {
        File exampleFile
        {
            SourcePath = "\\WIN-U20DTKMF9RA\c$\share\test.txt"
            DestinationPath = "C:\testDC.txt"
            Credential = $credential
        }
    }
}

if( $null -eq $credential )
{
    $credential = Get-Credential -Message "Remote credentials"
}

$mofs = CredentialEncryptionExample -credential $credential -ConfigurationData $ConfigData

foreach ($configMof in $Mofs)
{
    $dest = "C:\pullserver\Configuration\$($configmof.name)"
    copy $configMof.FullName $dest
    New-DSCChecksum $dest -Force
}