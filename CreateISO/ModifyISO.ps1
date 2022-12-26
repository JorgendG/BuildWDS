$VerbosePreference = "Continue"
function InstallOSCDIMG {
    <#
        .SYNOPSIS
        Install Oscdimg.

        .DESCRIPTION
        Download and install Oscdimg.
        Oscdimg can be used to create an ISO file

        .INPUTS
        None.

        .OUTPUTS
        None.

    #>
    Write-Verbose "Downloading oscdimg"
    $adkinstallerroot = 'https://download.microsoft.com/download/1/f/d/1fd2291e-c0e9-4ae0-beae-fbbe0fe41a5a/adk/Installers/'
    $oscdfiles = '1ac6852d8cf69114a2f7c4872d489325.cab', 'Oscdimg (DesktopEditions)-x86_en-us.msi', '52be7e8e9164388a9e6c24d01f6f1625.cab',
    '9d2b092478d6cca70d5ac957368c00ba.cab', '5d984200acbde182fd99cbfbe9bad133.cab', 'bbf55224a0290f00676ddc410f004498.cab'

    foreach ( $oscdfile in $oscdfiles ) {
        Invoke-WebRequest -Uri "$adkinstallerroot$oscdfile" -OutFile "C:\Windows\Temp\$oscdfile"
    }

    $MSIArguments = @(
        "/i"
            ('"{0}"' -f 'C:\Windows\Temp\Oscdimg (DesktopEditions)-x86_en-us.msi')
        "/qn"
        "/norestart"
    )

    Write-Verbose "Installing oscdimg"
    try {
        Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait -NoNewWindow
        Write-Verbose "Installed oscdimg"
    }
    catch {
        Write-Warning $Error[0]
    }
}

function PathOSCDIMG {
    $softwarekey = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows Kits\Installed Roots'

    Get-ItemProperty -Path $softwarekey -Name 'KitsRoot10' -ErrorAction SilentlyContinue
}

function CopyISO {
    param (
        [Parameter(Mandatory = $true)]
        $IsoFile,
        [Parameter(Mandatory = $true)]
        $MountFolder
    )
    <#
        .SYNOPSIS
        Copy contents of a ISO file.

        .DESCRIPTION
        Mount and extract files from a ISO file.

        .PARAMETER IsoFile
        Specifies the ISO file name.

        .PARAMETER MountFolder
        Specifies where the ISO is copied to.

        .INPUTS
        None.

        .OUTPUTS
        None.

        .EXAMPLE
        PS> CopyISO -IsoFile D:\ISO\20348.169.210806-2348.fe_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso MountFolder D:\Mount

    #>

    try {
        $iso = Mount-DiskImage $isofile -ErrorAction Stop
        $isodrive = $iso | Get-Volume
        New-Item $mountfolder -ItemType Directory -ErrorAction Stop

        Copy-Item $($isodrive.DriveLetter + ":\*") -Destination $mountfolder -Recurse
    }
    catch {
        Write-Warning $Error[0]
    }
    finally {
        if ( $iso ) { $iso | Dismount-DiskImage }
    }
}

function MakeAutounattend {
    param (
        [Parameter(Mandatory = $true)]
        $FileName,
        [Parameter(Mandatory = $true)]
        [PSCredential] 
        $adminPassword,
        [Parameter(Mandatory = $true)]
        [String] 
        $ScriptUri
    )
    <#
        .SYNOPSIS
        Create an autounattend.xml file.

        .DESCRIPTION
        Create an autounattend.xml file for an unattended Windows installation.

        .PARAMETER FileName
        Specifies the autounattend.xml file name.

        .PARAMETER adminPassword
        Specifies password for the built-in administrator account.

        .PARAMETER ScriptUri
        Specifies url url of the PowerShell script which runs after setup completes.

        .INPUTS
        None.

        .OUTPUTS
        None.

        .EXAMPLE
        PS> MakeAutounattend FileName D:\Mount\autounattend.xml (Get-Credential) "https://github.com/JorgendG/BuildWDS/raw/master/InstallWDS.ps1"

    #>

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
                        <Path>cmd /c echo powershell.exe -command &quot;&amp; {  wget -uri &apos;https://PathToScript.ps1&apos; -OutFile &apos;c:\windows\temp\script.ps1&apos; }&quot; &gt;&gt; c:\windows\setup\scripts\setupcomplete.cmd</Path>
                        <Order>2</Order>
                    </RunSynchronousCommand>
                    <RunSynchronousCommand wcm:action="add">
                        <Path>cmd /c echo powershell -file c:\windows\temp\script.ps1  &gt;&gt; c:\windows\setup\scripts\setupcomplete.cmd</Path>
                        <Order>3</Order>
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
                        <Value>EncryptedPassword</Value>
                        <PlainText>false</PlainText>
                    </AdministratorPassword>
                </UserAccounts>
            </component>
        </settings>
    </unattend>
    '

    $encrpwd = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes(('{0}AdministratorPassword' -f ($adminPassword.GetNetworkCredential().password) )))
    $passoobeSystem = $unattendxml.unattend.settings | Where-Object { $_.pass -eq 'oobeSystem' }
    $passoobeSystem.component.UserAccounts.AdministratorPassword.Value = $encrpwd

    $passspecialize = $unattendxml.unattend.settings | Where-Object { $_.pass -eq 'specialize' }
    $compMWD = $passspecialize.component | Where-Object { $_.name -eq 'Microsoft-Windows-Deployment' }
    $RunSynchronousCommand = $compMWD.RunSynchronous.RunSynchronousCommand

    $newPath = 'cmd /c echo powershell.exe -command "& {  wget -uri ' + $ScriptUri + ' -OutFile ''c:\windows\temp\script.ps1'' }" >> c:\windows\setup\scripts\setupcomplete.cmd'
    $RunSynchronousCommand[1].Path = $newPath
  
    $unattendxml.Save( $filename )
}

function MakeISO {
    param (
        [Parameter(Mandatory = $true)]
        $MountFolder,
        [Parameter(Mandatory = $true)]
        $NewIso
    )
    <#
        .SYNOPSIS
        Create an ISO file.

        .DESCRIPTION
        Create an ISO file from a folder containing Windows setup files.

        .PARAMETER MountFolder
        Specifies the folder containing the Windows Setup files.

        .PARAMETER NewIso
        Specifies filename for the new ISO.

        .INPUTS
        None.

        .OUTPUTS
        None.

        .EXAMPLE
        PS> MakeISO D:\Mount C:\tst\wds01.iso

    #>
    $OscdimgArguments = @(
        "-m"
        "-o"
        "-u2"
        "-udfver102"
        "-bootdata:2#p0,e,b$($MountFolder)\boot\etfsboot.com#pEF,e,b$($MountFolder)\efi\microsoft\boot\efisys.bin"
        "$MountFolder"
        "$newiso"
    )
    Write-Verbose "Writing $mountfolder as $NewIso"
    $Oscdimgexe = "$((PathOSCDIMG).KitsRoot10)" + "Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\Oscdimg.exe"
    Start-Process "$oscdimgexe" -ArgumentList $OscdimgArguments -Wait -NoNewWindow
}

# ===============================================================
#   Start main script
# ===============================================================
$isofile = "C:\tst\20348.169.210806-2348.fe_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
#$ScriptUri = "https://github.com/JorgendG/BuildWDS/raw/master/InstallWDS.ps1"
$ScriptUri = "https://github.com/JorgendG/BuildWDS/raw/reorganize/InstallWDS.ps1"
$mountfolder = "c:\Mount" 

if ( $null -eq (PathOSCDIMG) ) {
    InstallOSCDIMG
}


CopyISO $isofile $mountfolder

$credential = Get-Credential -Message "Administrator credentials" -UserName 'wds01\administrator'
$unattendxml = MakeAutounattend -FileName "$mountfolder\autounattend.xml" -adminPassword $credential -ScriptUri $ScriptUri

MakeISO -MountFolder $mountfolder -NewIso C:\tst\wds2022.iso


