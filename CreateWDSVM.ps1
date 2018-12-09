if( $cred -eq $null)
{
    $cred = Get-Credential
}
$vm = "WDS01"
$sourcedir = "\\nasje\public\wim"

Invoke-Command -ComputerName hyperhyper -ScriptBlock {

    $sess = New-PSSession -VMName $using:vm -Credential $using:cred

    Invoke-Command -Session $sess -ScriptBlock {Rename-Computer -NewName WDS01 -Force}
    Invoke-Command -Session $sess -ScriptBlock {Restart-Computer -Force}
    Start-Sleep -Seconds 60
    $sess = New-PSSession -VMName $using:vm -Credential $using:cred
    Invoke-Command -Session $sess -ScriptBlock {New-Item -ItemType Directory -Path c:\ -Name WDSImages}
    Copy-Item -Path "$using:sourcedir\boot.wim" -Destination c:\WDSImages -ToSession $sess
    Copy-Item -Path "$using:sourcedir\install2016.wim" -Destination c:\WDSImages -ToSession $sess
    Copy-Item -Path "$using:sourcedir\install2012r2.wim" -Destination c:\WDSImages -ToSession $sess
    Copy-Item -Path "$using:sourcedir\unattended.xml" -Destination c:\WDSImages -ToSession $sess
    Invoke-Command -Session $sess -ScriptBlock {add-windowsfeature WDS -includeall }
    Invoke-Command -Session $sess -ScriptBlock { & wdsutil.exe /initialize-server /reminst:'c:\remoteinstall' /standalone }
    Invoke-Command -Session $sess -ScriptBlock { New-WdsInstallImageGroup -Name 'Windows Server 2016' }
    Invoke-Command -Session $sess -ScriptBlock { New-WdsInstallImageGroup -Name 'Windows Server 2012R2' }
    Invoke-Command -Session $sess -ScriptBlock { Import-WdsBootImage -Path c:\wdsimages\boot.wim -NewDescription 'W2K16 WDS Boot' }
    Invoke-Command -Session $sess -ScriptBlock { Import-WdsInstallImage -Path c:\wdsimages\install2016.wim -ImageName 'Windows Server 2016 SERVERSTANDARD' -ImageGroup 'Windows Server 2016' }
    Invoke-Command -Session $sess -ScriptBlock { Import-WdsInstallImage -Path c:\wdsimages\install2012r2.wim -ImageName 'Windows Server 2012 R2 SERVERSTANDARD' -ImageGroup 'Windows Server 2012R2' }
    
    Invoke-Command -Session $sess -ScriptBlock { & wdsutil.exe /Set-Server /AnswerClients:All }
}
