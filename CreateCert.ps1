# note: These steps need to be performed in an Administrator PowerShell session
$dsccert = New-SelfSignedCertificate -Type DocumentEncryptionCertLegacyCsp -DnsName 'DscEncryptionCert' -HashAlgorithm SHA256 -NotAfter (Get-Date).AddYears(5)
# export the public key certificate
$dsccert | Export-Certificate -FilePath "c:\windows\temp\DscPublicKey.cer" -Force

$mypwd = ConvertTo-SecureString -String "1234" -Force -AsPlainText
$dsccert | Export-PfxCertificate -FilePath "c:\windows\temp\DscPrivatePublicKey.pfx" -Password $mypwd

$sslcert = New-SelfSignedCertificate -DnsName "wds01", "wds01.homelab.local" -CertStoreLocation "cert:\LocalMachine\My"
$sslcert | Export-PfxCertificate -FilePath "c:\windows\temp\SSLPrivatePublicKey.pfx" -Password $mypwd
