# iso gemaakt met een autounattend.xml
# oscdimg.exe -m -o -u2 -udfver102 -bootdata:2#p0,e,bc:\temp\iso\boot\etfsboot.com#pEF,e,bc:\temp\iso\efi\microsoft\boot\efisys.bin c:\temp\iso c:\temp\wds01.iso
start-transcript -path c:\windows\temp\installwds.txt

$sourcedirmodules = "\\nasje\public\modules"
$sourcediragents = "\\nasje\public\agents"

#[Net.ServicePointManager]::SecurityProtocol='tls12,tls11,tls'
#Install-Module CertificateDsc -Force
# Argh, install-module klapt eruit omdat er nog geen default profiel is
# $env:LOCALAPPDATA is namelijk leeg
# powershellget versie 2.2.3
# Lelijke workaround, kopieer modules van een lokale bron
# lelijk omdat er dan geen versiebeheer is, install-module pakt de laatste versie online
# Oplossing?
# Onderstaande code via een eenmalige(?) scheduled task uitvoeren die heel snel volgt op het huidige moment. Als setupcomplete.cmd is 
# afgerond is er vast een default profile waardoor install-module wel werkt

#Copy-Item $sourcedirmodules\xPSDesiredStateConfiguration 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Force
#Copy-Item $sourcedirmodules\SqlServerDsc 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Force
Copy-Item $sourcedirmodules\cWDS 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Force
#Copy-Item $sourcedirmodules\xPendingReboot 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Force
Copy-Item $sourcediragents\managementagentx64.msi 'C:\Windows\Temp' -Recurse -Force

#Install-PackageProvider -Name "Nuget" -Force
#Register-PackageSource -Name chocolatey -Location http://chocolatey.org/api/v2 -ProviderName NuGet -Trusted -Verbose
#Install-Package -Name sql-server-management-studio -ProviderName chocolatey -force

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main" -Name "DisableFirstRunCustomize" -Value 2

$win32cs = Get-WmiObject -query 'select * from Win32_ComputerSystem'

if( $win32cs.Manufacturer -eq 'Xen')
{
    $MSIArguments = @(
        "/i"
        ('"{0}"' -f "c:\windows\temp\managementagentx64.msi")
        "/qn"
        "/norestart"
    )
    Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait -NoNewWindow
}

$xmlunattend = [xml]'<unattend xmlns="urn:schemas-microsoft-com:unattend">
            <settings pass="windowsPE">
                <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                    <SetupUILanguage>
                        <UILanguage>en-US</UILanguage>
                    </SetupUILanguage>
                    <SystemLocale>en-US</SystemLocale>
                    <UILanguage>en-US</UILanguage>
                    <UserLocale>en-US</UserLocale>
                </component>
                <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                   <Diagnostics>
                        <OptIn>false</OptIn>
                    </Diagnostics>
                    <DiskConfiguration>
                        <WillShowUI>OnError</WillShowUI>
                        <Disk wcm:action="add">
                            <DiskID>0</DiskID>
                            <WillWipeDisk>true</WillWipeDisk>
                            <CreatePartitions>
                                <CreatePartition wcm:action="add">
                                    <Order>1</Order>
                                    <Size>100</Size>
                                    <Type>EFI</Type>
                                </CreatePartition>
                                <CreatePartition wcm:action="add">
							        <Order>2</Order> 
							        <Type>MSR</Type> 
							        <Size>128</Size> 
                                </CreatePartition>
                                <CreatePartition wcm:action="add">
							        <Order>3</Order> 
							        <Type>Primary</Type> 
							        <Extend>true</Extend> 
                                </CreatePartition>
                            </CreatePartitions>
                            <ModifyPartitions>
                                <ModifyPartition wcm:action="add">
							        <Order>1</Order> 
							        <PartitionID>1</PartitionID> 
							        <Label>System</Label> 
							        <Format>FAT32</Format> 
						        </ModifyPartition>
						        <ModifyPartition wcm:action="add">
							        <Order>2</Order> 
							        <PartitionID>3</PartitionID> 
							        <Label>Local Disk</Label> 
							        <Letter>C</Letter> 
							        <Format>NTFS</Format> 
						        </ModifyPartition>
					        </ModifyPartitions>
                        </Disk>
                    </DiskConfiguration>
                    <ImageInstall>
                        <OSImage>
                            <InstallTo>
                                <DiskID>0</DiskID>
                                <PartitionID>3</PartitionID>
                            </InstallTo>
                            <WillShowUI>OnError</WillShowUI>
                            <InstallToAvailablePartition>false</InstallToAvailablePartition>
                        </OSImage>
                    </ImageInstall>
                    <UserData>
                        <AcceptEula>true</AcceptEula>
                        <FullName></FullName>
                        <Organization></Organization>
                        <ProductKey>
                            <WillShowUI>Never</WillShowUI>
                        </ProductKey>
                    </UserData>
                    <EnableFirewall>true</EnableFirewall>
                    <EnableNetwork>true</EnableNetwork>
                    <WindowsDeploymentServices>
                        <Login>
                            <Credentials>
                                <Username></Username>
                                <Password></Password>
                                <Domain></Domain>
                            </Credentials>
                        </Login>
                        <ImageSelection>
                            <InstallImage>
                                <ImageName></ImageName>
                                <ImageGroup></ImageGroup>
                            </InstallImage>
                            <InstallTo>
                                <DiskID>0</DiskID>
                                <PartitionID>3</PartitionID>
                            </InstallTo>
                        </ImageSelection>
                    </WindowsDeploymentServices>
                </component>
            </settings>
            <settings pass="generalize">
                <component name="Microsoft-Windows-Security-SPP" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                    <SkipRearm>1</SkipRearm>
                </component>
                <component name="Microsoft-Windows-PnpSysprep" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                    <PersistAllDeviceInstalls>true</PersistAllDeviceInstalls>
                </component>
            </settings>
            <settings pass="specialize">
                <component name="Microsoft-Windows-Security-SPP-UX" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                    <SkipAutoActivation>true</SkipAutoActivation>
                </component>
                <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                    <TimeZone>GMT Standard Time</TimeZone>
                    <ComputerName>TEMPLATE</ComputerName>
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
                            <Active>true</Active>
                            <Group>Remote Desktop</Group>
                        </FirewallGroup>
                    </FirewallGroups>
                </component>
            </settings>
            <settings pass="oobeSystem">
                <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                    <UserAccounts>
                        <AdministratorPassword>
                            <Value>MQAyAHcAcQAhAEAAVwBRAEEAZABtAGkAbgBpAHMAdAByAGEAdABvAHIAUABhAHMAcwB3AG8AcgBkAA==</Value>
                            <PlainText>false</PlainText>
                        </AdministratorPassword>
                    </UserAccounts>
                    <OOBE>
                        <HideEULAPage>true</HideEULAPage>
                        <SkipMachineOOBE>true</SkipMachineOOBE>
                        <SkipUserOOBE>true</SkipUserOOBE>
                        <NetworkLocation>Work</NetworkLocation>
                        <ProtectYourPC>3</ProtectYourPC>
                        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                    </OOBE>
                    <TimeZone>W. Europe Standard Time</TimeZone>
                    <DisableAutoDaylightTimeSet>false</DisableAutoDaylightTimeSet>
                </component>
            </settings>
        </unattend>'
$winpe = $xmlunattend.unattend.settings | Where-Object{ $_.pass -eq 'windowsPE' }
$winpe.component.Where( {$_.name -eq 'Microsoft-Windows-International-Core-WinPE'} )
$winpe.component.Where( {$_.name -eq 'Microsoft-Windows-Setup'} ).WindowsDeploymentServices.Login.Credentials.Username = 'administrator'
$winpe.component.Where( {$_.name -eq 'Microsoft-Windows-Setup'} ).WindowsDeploymentServices.Login.Credentials.Password = '12wq!@WQ'
$winpe.component.Where( {$_.name -eq 'Microsoft-Windows-Setup'} ).WindowsDeploymentServices.Login.Credentials.Domain = 'wds01'

$xmlunattend.Save( "c:\windows\temp\unattend.xml" )

Invoke-WebRequest -Uri https://github.com/JorgendG/BuildWDS/raw/master/PullServerSQL.ps1 -OutFile C:\Windows\Temp\PullServerSQL.ps1
Invoke-WebRequest -Uri https://github.com/JorgendG/BuildWDS/raw/master/ConfigPullServer.ps1 -OutFile C:\Windows\Temp\ConfigPullServer.ps1
Invoke-WebRequest -Uri https://github.com/JorgendG/BuildWDS/raw/master/DscPrivatePublicKey.pfx -OutFile C:\Windows\Temp\DscPrivatePublicKey.pfx

$mypwd = ConvertTo-SecureString -String "1234" -Force -AsPlainText
Import-PfxCertificate -FilePath C:\Windows\Temp\DscPrivatePublicKey.pfx -Password $mypwd -CertStoreLocation Cert:\LocalMachine\My

$taskName = "PullServerSQL"
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($null -ne $task)
{
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false 
}

# TODO: EDIT THIS STUFF AS NEEDED...
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-File "C:\windows\temp\PullServerSQL.ps1"'
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -Compatibility Win8

$principal = New-ScheduledTaskPrincipal -UserId SYSTEM -LogonType ServiceAccount -RunLevel Highest

$definition = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings -Description "Run $($taskName) at startup"

Register-ScheduledTask -TaskName $taskName -InputObject $definition

$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

# TODO: LOG AS NEEDED...
if ($null -ne $task)
{
    Write-Output "Created scheduled task: '$($task.ToString())'."
}
else
{
    Write-Output "Created scheduled task: FAILED."
}

#& $env:TEMP\PullServerSQL.ps1

shutdown.exe /r /t 5