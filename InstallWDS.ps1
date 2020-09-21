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

Copy-Item $sourcedirmodules\xPSDesiredStateConfiguration 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Force
Copy-Item $sourcedirmodules\SqlServerDsc 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Force
Copy-Item $sourcedirmodules\cWDS 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Force
Copy-Item $sourcedirmodules\xPendingReboot 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Force
Copy-Item $sourcediragents\managementagentx64.msi 'C:\Windows\Temp' -Recurse -Force

Install-PackageProvider -Name "Nuget" -Force
Register-PackageSource -Name chocolatey -Location http://chocolatey.org/api/v2 -ProviderName NuGet -Trusted -Verbose
Install-Package -Name sql-server-management-studio -ProviderName chocolatey -force

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

Invoke-WebRequest -Uri https://github.com/JorgendG/BuildWDS/raw/master/PullServerSQL.ps1 -OutFile $env:TEMP\PullServerSQL.ps1
& $env:TEMP\PullServerSQL.ps1
