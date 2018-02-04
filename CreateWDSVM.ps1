if( $cred -eq $null)
{
    $cred = Get-Credential
}
$vm = "WDS01"

Invoke-Command -ComputerName hyperhyper -ScriptBlock {

    $sess = New-PSSession -VMName $using:vm -Credential $using:cred

    Invoke-Command -Session $sess -ScriptBlock {Rename-Computer -NewName WDS01 -Force}
    Invoke-Command -Session $sess -ScriptBlock {Restart-Computer -Force}
    Start-Sleep -Seconds 20
    $sess = New-PSSession -VMName $using:vm -Credential $using:cred
    Invoke-Command -Session $sess -ScriptBlock {New-Item -ItemType Directory -Path c:\ -Name WDSImages}
    Copy-Item -Path 'D:\WDSImages\boot.wim' -Destination c:\WDSImages -ToSession $sess
    Copy-Item -Path 'D:\WDSImages\install.wim' -Destination c:\WDSImages -ToSession $sess
    Copy-Item -Path 'D:\WDSImages\install2012r2.wim' -Destination c:\WDSImages -ToSession $sess
    Copy-Item -Path 'D:\WDSImages\unattended.xml' -Destination c:\WDSImages -ToSession $sess
    Invoke-Command -Session $sess -ScriptBlock {add-windowsfeature WDS -includeall }
    Invoke-Command -Session $sess -ScriptBlock { & wdsutil.exe /initialize-server /reminst:'c:\remoteinstall' /standalone }
    Invoke-Command -Session $sess -JobName { New-WdsInstallImageGroup -Name 'Windows Server 2016' }
    Invoke-Command -Session $sess -JobName { New-WdsInstallImageGroup -Name 'Windows Server 2012R2' }
    Invoke-Command -Session $sess -JobName { Import-WdsBootImage -Path c:\wdsimages\boot.wim -NewDescription 'W2K16 WDS Boot' }
    Invoke-Command -Session $sess -JobName { Import-WdsInstallImage -Path c:\wdsimages\install.wim -ImageName 'Windows Server 2016 SERVERSTANDARD' -ImageGroup 'Windows Server 2016' }
    Invoke-Command -Session $sess -JobName { Import-WdsInstallImage -Path c:\wdsimages\install2012r2.wim -ImageName 'Windows Server 2012 R2 SERVERSTANDARD' -ImageGroup 'Windows Server 2012R2' }

    
    Invoke-Command -Session $sess -ScriptBlock { & wdsutil.exe /add-image /imagefile:c:\wdsimages\boot.wim /imagetype:boot /name:'W2K16 WDS Boot' /filename:'wdsboot.wim' }
    #Invoke-Command -Session $sess -ScriptBlock { & wdsutil.exe /add-image /ImageFile:c:\wdsimages\install.wim /ImageType:install /imagegroup:'Windows Server 2016' /filename:'install.wim' /UnattendedFile:'c:\wdsimages\unattended.xml' }
    Invoke-Command -Session $sess -ScriptBlock { & wdsutil.exe /add-image /ImageFile:c:\wdsimages\install2012r2.wim /ImageType:install /imagegroup:'Windows Server 2012R2' /filename:'install.wim' }
    Invoke-Command -Session $sess -ScriptBlock { & wdsutil.exe /Set-Server /AnswerClients:All }
}


Invoke-Command -Session $sess -ScriptBlock {

}


Invoke-Command -ComputerName hyperhyper -ScriptBlock {

    $sess = New-PSSession -VMName $using:vm -Credential $using:cred
    Invoke-Command -Session $sess -ScriptBlock { & wdsutil.exe /add-image /ImageFile:c:\wdsimages\install.wim /ImageType:install /imagegroup:'Windows Server 2016' /filename:'install.wim' /UnattendFile:'c:\wdsimages\unattended.xml' }
}