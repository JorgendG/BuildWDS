Unregister-ScheduledTask -TaskName 'InstallDSCModules' -Confirm:$false

function New-UnattendXML {
    param (
        [Parameter(Mandatory = $true)]
        $FileName,
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $WDSCredential
    )
    <#
        .SYNOPSIS
        Create an autounattend.xml file.

        .DESCRIPTION
        Create an autounattend.xml file for an unattended Windows installation.

        .PARAMETER FileName
        Specifies the autounattend.xml file name.

        .PARAMETER WDSCredential
        Specifies password for the built-in administrator account.

        .INPUTS
        None.

        .OUTPUTS
        None.

        .EXAMPLE
        PS> New-AutoUnattend -FileName D:\Mount\autounattend.xml -WDSCredential (Get-Credential)

    #>

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
                <component name="Microsoft-Windows-IE-InternetExplorer" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	                <DisableFirstRunWizard>true</DisableFirstRunWizard>
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
                <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                    <RunSynchronous>
                        <RunSynchronousCommand wcm:action="add">
                            <Path>cmd /c md c:\windows\setup\scripts</Path>
                            <Order>1</Order>
                            </RunSynchronousCommand>
                        <RunSynchronousCommand wcm:action="add">
                            <Path>cmd /c echo powershell.exe -command &quot;&amp; {invoke-webrequest -uri &apos;http://wds01/Bootstrap.txt&apos; -OutFile &apos;c:\windows\temp\script.ps1&apos; }&quot; &gt; c:\windows\setup\scripts\setupcomplete.cmd</Path>
                            <Order>2</Order>
                        </RunSynchronousCommand>
                        <RunSynchronousCommand wcm:action="add">
                            <Path>cmd /c echo powershell.exe -command "&amp; {set-executionpolicy bypass -Force }" &gt;&gt; c:\windows\setup\scripts\setupcomplete.cmd</Path>
                            <Order>3</Order>
                        </RunSynchronousCommand>
                        <RunSynchronousCommand wcm:action="add">
                            <Path>cmd /c echo powershell -file c:\windows\temp\script.ps1 &gt;&gt; c:\windows\setup\scripts\setupcomplete.cmd</Path>
                            <Order>4</Order>
                        </RunSynchronousCommand>
                        <RunSynchronousCommand wcm:action="add">
                            <Path>net user administrator /active:yes</Path>
                            <Order>5</Order>
                        </RunSynchronousCommand>
                    </RunSynchronous>
                </component>
            </settings>
            <settings pass="oobeSystem">
                <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                    <UserAccounts>
                        <AdministratorPassword>
                            <Value/>
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


    $WDSCredential.GetNetworkCredential().password
    $winpe = $xmlunattend.unattend.settings | Where-Object { $_.pass -eq 'windowsPE' }
    $winpe.component.Where( { $_.name -eq 'Microsoft-Windows-International-Core-WinPE' } )
    $winpe.component.Where( { $_.name -eq 'Microsoft-Windows-Setup' } ).WindowsDeploymentServices.Login.Credentials.Username = $WDSCredential.GetNetworkCredential().UserName
    $winpe.component.Where( { $_.name -eq 'Microsoft-Windows-Setup' } ).WindowsDeploymentServices.Login.Credentials.Password = $WDSCredential.GetNetworkCredential().Password
    $winpe.component.Where( { $_.name -eq 'Microsoft-Windows-Setup' } ).WindowsDeploymentServices.Login.Credentials.Domain = $WDSCredential.GetNetworkCredential().Domain

    $xmlunattend.Save( $FileName )
}

# Install DSC Modules
Install-PackageProvider -Name "Nuget" -Force

$requiredmodules = 'xPSDesiredStateConfiguration', 'ComputerManagementDsc', 'SqlServerDsc', 'NetworkingDsc', 'DnsServerDsc', 'xDefender'
Install-Module $requiredmodules -Force

#Install custom DSC WDS module
New-Item -Path 'C:\Program Files\WindowsPowerShell\Modules\cWDS' -ItemType Directory
Invoke-WebRequest -Uri https://github.com/JorgendG/cWDS/raw/master/cWDS.psd1 -OutFile 'C:\Program Files\WindowsPowerShell\Modules\cWDS\cWDS.psd1'
Invoke-WebRequest -Uri https://github.com/JorgendG/cWDS/raw/master/cWDS.psm1 -OutFile 'C:\Program Files\WindowsPowerShell\Modules\cWDS\cWDS.psm1'

<#
# Create local user used for unattended installs
$mypwd = ConvertTo-SecureString -String "P@ssword!" -Force -AsPlainText
New-LocalUser -Name readonly -Password $mypwd -AccountNeverExpires:$true

$credential = New-Object `
    -TypeName System.Management.Automation.PSCredential `
    -ArgumentList "wds01\readonly", $mypwd

New-UnattendXML -FileName c:\windows\temp\unattend.xml -WDSCredential $credential
#>

$githubrepo = "https://github.com/JorgendG/BuildWDS/raw/reorganize"
Invoke-WebRequest -Uri "$githubrepo/DscPrivatePublicKey.pfx" -OutFile C:\Windows\Temp\DscPrivatePublicKey.pfx
Invoke-WebRequest -Uri "$githubrepo/DscPublicKey.cer" -OutFile C:\Windows\Temp\DscPublicKey.cer
$mypwd = ConvertTo-SecureString -String "1234" -Force -AsPlainText
Import-PfxCertificate -FilePath C:\Windows\Temp\DscPrivatePublicKey.pfx -Password $mypwd -CertStoreLocation Cert:\LocalMachine\My

# Download and run the DSC config
Invoke-WebRequest -Uri "$githubrepo/WDSServer/ConfigPullServer.psd1" -OutFile C:\Windows\Temp\ConfigPullServer.psd1
Invoke-WebRequest -Uri "$githubrepo/WDSServer/ConfigPullServer.ps1" -OutFile C:\Windows\Temp\ConfigPullServer.ps1

& C:\Windows\Temp\ConfigPullServer.ps1
