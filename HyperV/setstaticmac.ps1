Start-Transcript -Path c:\scripts\prepvm.txt -Append


$lastevent = Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-Hyper-V-VMMS-Admin'; Id = 18304 } -MaxEvents 1

#$s = "The virtual machine 'CA1' was realized. (VMID B75F7F28-B944-466D-896E-150B20283664)."
$s = $lastevent.Message
$newvmname = [regex]::matches($s, "(?<=\').+?(?=\')").value

$newvm = Get-VM -Name $newvmname

if ( $newvm.State -eq 'Off' ) {
    $firstbootorder = (Get-VMFirmware -VM $newvm).BootOrder[0]
    if ( $firstbootorder.BootType -eq 'Network' ) {
        $vmnic = Get-VM -Name $newvmname | Get-VMNetworkAdapter

        $arr_byte = New-Object Byte[] 6
        $arr_byte[0] = 2

        $nics = Get-VMNetworkAdapter -All

        for ($i = 0; $i -lt 99; $i++) { 
            $arr_byte[5] = $i
            $checkmac = ([System.BitConverter]::ToString($arr_byte)).Replace( '-', '' )
            if ( $null -eq ($nics | Where-Object { $_.MacAddress -eq $checkmac })  ) {
                $newmac = [System.BitConverter]::ToString($arr_byte)
                Set-VMNetworkAdapter -VMNetworkAdapter $vmnic -StaticMacAddress $newmac
                $newmac

                $newvmnameNB = ($newvmname -split ':')[0]
                $newvmnameOS = ($newvmname -split ':')[2]

                switch ($newvmnameOS) {
                    # ja, hier kan wel iets geoptimaliseerd worden. 
                    'w10' { $unattendfile = 'installwin10.xml' }
                    'w11' { $unattendfile = 'installwin11.xml' }
                    's2012r2' { $unattendfile = 'install2012r2.xml' }
                    's2016' { $unattendfile = 'install2016.xml' }
                    's2019' { $unattendfile = 'install2019.xml' }
                    's2022' { $unattendfile = 'install2022.xml' }
                    Default { $unattendfile = 'install2019.xml' }
                }

                $password = ConvertTo-SecureString '12wq!@WQ' -AsPlainText -Force
                $credwds = New-Object System.Management.Automation.PSCredential ('wds01\administrator', $password)

                Invoke-Command -ComputerName wds01 -Credential $credwds -ScriptBlock `
                {
                    Get-WdsClient -DeviceName $using:newVMnamenb | Remove-WdsClient
                    Get-WdsClient -DeviceId $using:newmac | Remove-WdsClient
                    New-WdsClient -DeviceName $using:newVMnamenb -DeviceID $using:newmac -PxePromptPolicy NoPrompt `
                        -WdsClientUnattend "WdsClientUnattend\$using:unattendfile" -JoinDomain:$false
                }
                Start-VM $newvm
                break
            }

        }

        
    }
}

Stop-Transcript