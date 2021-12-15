$class = cimclass MSFT_TaskEventTrigger root/Microsoft/Windows/TaskScheduler
$trigger = $class | New-CimInstance -ClientOnly

$trigger.Enabled = $true

$trigger.Subscription = '<QueryList><Query Id="0" `
Path="Microsoft-Windows-Hyper-V-VMMS-Admin"><Select `
Path="Microsoft-Windows-Hyper-V-VMMS-Admin">`
*[System[Provider[@Name=''Microsoft-Windows-Hyper-V-VMMS''] `
and EventID=18304]]</Select></Query></QueryList>'

$ActionParameters = @{
 Execute  = 'C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe'
 Argument = '-NoProfile -File C:\scripts\setstaticmac.ps1'
}

$Action = New-ScheduledTaskAction @ActionParameters
$Principal = New-ScheduledTaskPrincipal -UserId 'NT AUTHORITY\SYSTEM' -LogonType ServiceAccount
$Settings = New-ScheduledTaskSettingsSet

$RegSchTaskParameters = @{
    TaskName    = 'Register WDS'
    Description = 'runs at new VM'
    TaskPath    = '\'
    Action      = $Action
    Principal   = $Principal
    Settings    = $Settings
    Trigger     = $Trigger
}

Register-ScheduledTask @RegSchTaskParameters


