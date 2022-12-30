$githubrepo = "https://github.com/JorgendG/BuildWDS/raw/reorganize"

Invoke-WebRequest -Uri "$githubrepo/WDSServer/InstallDSCModules.ps1" -OutFile C:\Windows\Temp\InstallDSCModules.ps1


# When this script is executed, the local environment hasn't been setup and install-module won't work
# Create a scheduled task which runs after a reboot. After this reboot, the local environment is ready for install-module
$taskName = "InstallDSCModules"
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($null -ne $task) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false 
}

$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-File "C:\windows\temp\InstallDSCModules.ps1"'
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -Compatibility Win8

$principal = New-ScheduledTaskPrincipal -UserId SYSTEM -LogonType ServiceAccount -RunLevel Highest
$definition = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings -Description "Run $($taskName) at startup"
Register-ScheduledTask -TaskName $taskName -InputObject $definition

shutdown.exe /r /t 5
