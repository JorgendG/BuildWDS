$VerbosePreference="Continue"
function InstallOSCDIMG
 {
    Write-Verbose "Downloading oscdimg"
    Invoke-WebRequest -Uri 'https://download.microsoft.com/download/1/f/d/1fd2291e-c0e9-4ae0-beae-fbbe0fe41a5a/adk/Installers/1ac6852d8cf69114a2f7c4872d489325.cab' -OutFile 'C:\Windows\Temp\1ac6852d8cf69114a2f7c4872d489325.cab'
    Invoke-WebRequest -Uri 'https://download.microsoft.com/download/1/f/d/1fd2291e-c0e9-4ae0-beae-fbbe0fe41a5a/adk/Installers/Oscdimg (DesktopEditions)-x86_en-us.msi' -OutFile 'C:\Windows\Temp\Oscdimg (DesktopEditions)-x86_en-us.msi'
    Invoke-WebRequest -Uri 'https://download.microsoft.com/download/1/f/d/1fd2291e-c0e9-4ae0-beae-fbbe0fe41a5a/adk/Installers/52be7e8e9164388a9e6c24d01f6f1625.cab' -OutFile 'C:\Windows\Temp\52be7e8e9164388a9e6c24d01f6f1625.cab'
    Invoke-WebRequest -Uri 'https://download.microsoft.com/download/1/f/d/1fd2291e-c0e9-4ae0-beae-fbbe0fe41a5a/adk/Installers/9d2b092478d6cca70d5ac957368c00ba.cab' -OutFile 'C:\Windows\Temp\9d2b092478d6cca70d5ac957368c00ba.cab'
    Invoke-WebRequest -Uri 'https://download.microsoft.com/download/1/f/d/1fd2291e-c0e9-4ae0-beae-fbbe0fe41a5a/adk/Installers/5d984200acbde182fd99cbfbe9bad133.cab' -OutFile 'C:\Windows\Temp\5d984200acbde182fd99cbfbe9bad133.cab'
    Invoke-WebRequest -Uri 'https://download.microsoft.com/download/1/f/d/1fd2291e-c0e9-4ae0-beae-fbbe0fe41a5a/adk/Installers/bbf55224a0290f00676ddc410f004498.cab' -OutFile 'C:\Windows\Temp\bbf55224a0290f00676ddc410f004498.cab'

    $MSIArguments = @(
            "/i"
            ('"{0}"' -f 'C:\Windows\Temp\Oscdimg (DesktopEditions)-x86_en-us.msi')
            "/qn"
            "/norestart"
        )
    Write-Verbose "Installing oscdimg"
    Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait -NoNewWindow
 }

 function CheckOSCDIMG
 {
     $softwarekey = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows Kits\Installed Roots'

     Get-ItemProperty -Path $softwarekey -Name '{B2CC0FA4-2C40-81F5-C0CD-3A3FAB81FE7E}' -ErrorAction SilentlyContinue
     
 }

 function PathOSCDIMG
 {
     $softwarekey = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows Kits\Installed Roots'

     Get-ItemProperty -Path $softwarekey -Name 'KitsRoot10' -ErrorAction SilentlyContinue
     
 }

function CopyISO {
    param (
        $isofile,
        $mountfolder
    )
    $iso = Mount-DiskImage $isofile
    $isodrive = $iso | Get-Volume
    New-Item $mountfolder -ItemType Directory

    Copy-Item $($isodrive.DriveLetter+":\*") -Destination $mountfolder -Recurse

    $iso | Dismount-DiskImage
    
}

function MakeAutounattend {
    param (
        $filename
    )
    $unattendxml = [xml]'<?xml version="1.0" encoding="utf-8"?>
    <unattend xmlns="urn:schemas-microsoft-com:unattend">
        <settings pass="windowsPE">
            <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <InputLocale>en-US</InputLocale>
                <SystemLocale>en-US</SystemLocale>
                <UILanguage>en-US</UILanguage>
                <UserLocale>en-US</UserLocale>
                <UILanguageFallback>en-US</UILanguageFallback>
            </component>
            <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <DiskConfiguration>
                    <WillShowUI>OnError</WillShowUI>
                    <Disk wcm:action="add">
                        <CreatePartitions>
                            <CreatePartition wcm:action="add">
                                <Order>1</Order>
                                <Size>500</Size>
                                <Type>Primary</Type>
                            </CreatePartition>
                            <CreatePartition wcm:action="add">
                                <Order>2</Order>
                                <Size>100</Size>
                                <Type>EFI</Type>
                            </CreatePartition>
                            <CreatePartition wcm:action="add">
                                <Order>3</Order>
                                <Size>16</Size>
                                <Type>MSR</Type>
                            </CreatePartition>
                            <CreatePartition wcm:action="add">
                                <Order>4</Order>
                                <Extend>true</Extend>
                                <Type>Primary</Type>
                            </CreatePartition>
                        </CreatePartitions>
                        <ModifyPartitions>
                            <ModifyPartition wcm:action="add">
                                <Format>NTFS</Format>
                                <Order>1</Order>
                                <Label>WinRE</Label>
                                <TypeID>DE94BBA4-06D1-4D40-A16A-BFD50179D6AC</TypeID>
                                <PartitionID>1</PartitionID>
                            </ModifyPartition>
                            <ModifyPartition wcm:action="add">
                                <Format>FAT32</Format>
                                <Label>System</Label>
                                <Order>2</Order>
                                <PartitionID>2</PartitionID>
                            </ModifyPartition>
                            <ModifyPartition wcm:action="add">
                                <Order>3</Order>
                                <PartitionID>3</PartitionID>
                            </ModifyPartition>
                            <ModifyPartition wcm:action="add">
                                <Format>NTFS</Format>
                                <Label>Windows</Label>
                                <Letter>C</Letter>
                                <Order>4</Order>
                                <PartitionID>4</PartitionID>
                            </ModifyPartition>
                        </ModifyPartitions>
                        <DiskID>0</DiskID>
                        <WillWipeDisk>true</WillWipeDisk>
                    </Disk>
                </DiskConfiguration>
                <ImageInstall>
                    <OSImage>
                        <InstallTo>
                            <DiskID>0</DiskID>
                            <PartitionID>4</PartitionID>
                        </InstallTo>
                        <InstallFrom>
                            <MetaData wcm:action="add">
                                <Key>/IMAGE/INDEX</Key>
                                <Value>2</Value>
                            </MetaData>
                        </InstallFrom>
                    </OSImage>
                </ImageInstall>
                <UserData>
                    <AcceptEula>true</AcceptEula>
                    <FullName>Homelab</FullName>
                    <Organization>Homelab</Organization>
                </UserData>
            </component>
        </settings>
        <settings pass="specialize">
            <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <ComputerName>WDS01</ComputerName>
                <RegisteredOrganization>Homelab</RegisteredOrganization>
                <RegisteredOwner>Homelab</RegisteredOwner>
                <TimeZone>W. Europe Standard Time</TimeZone>
            </component>
            <component name="Microsoft-Windows-TerminalServices-LocalSessionManager" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <fDenyTSConnections>false</fDenyTSConnections>
            </component>
            <component name="Microsoft-Windows-TerminalServices-RDP-WinStationExtensions" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <UserAuthentication>0</UserAuthentication>
            </component>
            <component name="Microsoft-Windows-IE-ESC" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <IEHardenAdmin>false</IEHardenAdmin>
                <IEHardenUser>false</IEHardenUser>
            </component>
            <component name="Microsoft-Windows-ServerManager-SvrMgrNc" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <DoNotOpenServerManagerAtLogon>true</DoNotOpenServerManagerAtLogon>
            </component>
            <component name="Networking-MPSSVC-Svc" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <FirewallGroups>
                    <FirewallGroup wcm:action="add" wcm:keyValue="rd1">
                        <Profile>all</Profile>
                        <Group>Remote Desktop</Group>
                        <Active>true</Active>
                    </FirewallGroup>
                </FirewallGroups>
            </component>
            <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <RunSynchronous>
                    <RunSynchronousCommand wcm:action="add">
                        <Path>cmd /c md c:\windows\setup\scripts</Path>
                        <Order>1</Order>
                    </RunSynchronousCommand>
                    <RunSynchronousCommand wcm:action="add">
                        <Order>2</Order>
                        <Path>cmd /c echo powershell.exe -command &quot;&amp; {start-transcript -path c:\windows\temp\wget.txt}&quot; &gt; c:\windows\setup\scripts\setupcomplete.cmd</Path>
                    </RunSynchronousCommand>
                    <RunSynchronousCommand wcm:action="add">
                        <Path>cmd /c echo powershell.exe -command &quot;&amp; {  wget -uri &apos;https://github.com/JorgendG/BuildWDS/raw/master/InstallWDS.ps1&apos; -OutFile &apos;c:\windows\temp\script.ps1&apos; }&quot; &gt;&gt; c:\windows\setup\scripts\setupcomplete.cmd</Path>
                        <Order>3</Order>
                    </RunSynchronousCommand>
                    <RunSynchronousCommand wcm:action="add">
                        <Path>cmd /c echo powershell -file c:\windows\temp\script.ps1  &gt;&gt; c:\windows\setup\scripts\setupcomplete.cmd</Path>
                        <Order>4</Order>
                    </RunSynchronousCommand>
                </RunSynchronous>
            </component>
        </settings>
        <settings pass="oobeSystem">
            <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <OOBE>
                    <NetworkLocation>Work</NetworkLocation>
                    <ProtectYourPC>3</ProtectYourPC>
                    <HideEULAPage>true</HideEULAPage>
                    <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                    <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                </OOBE>
                <UserAccounts>
                    <AdministratorPassword>
                        <Value>MQAyAHcAcQAhAEAAVwBRAEEAZABtAGkAbgBpAHMAdAByAGEAdABvAHIAUABhAHMAcwB3AG8AcgBkAA==</Value>
                        <PlainText>false</PlainText>
                    </AdministratorPassword>
                </UserAccounts>
            </component>
        </settings>
        <cpi:offlineImage cpi:source="wim:c:/users/administrator.homelabdsc/desktop/install.wim#Windows Server 2019 SERVERSTANDARD" xmlns:cpi="urn:schemas-microsoft-com:cpi" />
    </unattend>
    '
    $unattendxml.Save( $filename )
}

function MakeISO {
    param (
        $mountfolder,
        $newiso
    )

    $OscdimgArguments = @(
            "-m"
            "-o"
            "-u2"
            "-udfver102"
            "-bootdata:2#p0,e,b$($mountfolder)\boot\etfsboot.com#pEF,e,b$($mountfolder)\efi\microsoft\boot\efisys.bin"
            "$mountfolder"
            "$newiso"
        )
    Write-Verbose "Writing $mountfolder as $newiso"
    $Oscdimgexe = "$((PathOSCDIMG).KitsRoot10)"+"Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\Oscdimg.exe"
    Start-Process "$oscdimgexe" -ArgumentList $OscdimgArguments -Wait -NoNewWindow
}

if( (CheckOSCDIMG) -eq $null )
{
    InstallOSCDIMG
}

$isofile = "C:\Users\jwdeg\Downloads\20348.169.210806-2348.fe_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
CopyISO $isofile d:\mount
MakeAutounattend d:\mount\autounattend.xml

MakeISO D:\mount C:\temp\wds2022.iso


