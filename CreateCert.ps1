# note: These steps need to be performed in an Administrator PowerShell session
$cert = New-SelfSignedCertificate -Type DocumentEncryptionCertLegacyCsp -DnsName 'DscEncryptionCert' -HashAlgorithm SHA256 -NotAfter (Get-Date).AddYears(5)
# export the public key certificate
$cert | Export-Certificate -FilePath "c:\windows\temp\DscPublicKey.cer" -Force

$mypwd = ConvertTo-SecureString -String "1234" -Force -AsPlainText
$cert | Export-PfxCertificate -FilePath "c:\windows\temp\DscPrivatePublicKey.pfx" -Password $mypwd
