if( $cred -eq $null)
{
    $cred = Get-Credential
}
$wdsvm = "WDS01"

Invoke-Command -ComputerName hyperhyper -ScriptBlock {

    $sess = New-PSSession -VMName $using:wdsvm -Credential $using:cred
    Invoke-Command -Session $sess -ScriptBlock {
        $WDSimagegroup = "Windows Server 2016"
        $WDSimagename = "Windows Server 2016 SERVERSTANDARD"
        $VM = "TSTW16"

        $xml = [xml](Get-Content 'C:\WDSImages\unattend.xml')

        # Pas het image aan welke tijdens de uitrol gebruikt wordt
        $winPE = $xml.unattend.settings | Where-Object {$_.pass -eq 'windowsPE' }
        $core = $winPE.component | Where-Object {$_.name -eq 'Microsoft-Windows-Setup' }
        #$core.WindowsDeploymentServices.ImageSelection.InstallImage.Filename = 'install-(2).wim'
        $core.WindowsDeploymentServices.ImageSelection.InstallImage.ImageGroup = $WDSimagegroup
        $core.WindowsDeploymentServices.ImageSelection.InstallImage.ImageName = $WDSimagename

        # stel de computername in
        $spec = $xml.unattend.settings | Where-Object {$_.pass -eq 'specialize' }
        $compname = $spec.component | Where-Object {$_.Name -eq 'Microsoft-Windows-Shell-Setup' }
        $compname.ComputerName = $VM

        # stel de DSC config role in
        #$spec = $xml.unattend.settings | where {$_.pass -eq 'specialize' }
        #$deployment = $spec.component | where {$_.Name -eq 'Microsoft-Windows-Deployment' }
        #$roleregel = $deployment.RunSynchronous.RunSynchronousCommand | where{ $_.Order -eq 2}
        #$roleregel.Path = $roleregel.Path.Replace( "ConfigurationNames={`"DC`"}", "ConfigurationNames={`"$Role`"}")

        # schrijf weg naar nieuw xml bestand
        $xml.Save( "C:\RemoteInstall\WdsClientUnattend\unattend$VM.xml"  )

        ############################################################################
        # Maak prestaged device aan, hiermee wordt het Mac adres gekoppeld aan
        # de VM zodat tijdens de uitrol de computernaam ingevuld kan worden.
        ############################################################################
        Get-WdsClient -DeviceName $VM | Remove-WdsClient

        New-WdsClient -DeviceName $VM -DeviceID '00-15-5D-F6-8F-2A' -PxePromptPolicy NoPrompt `
                      -WdsClientUnattend "WdsClientUnattend\unattend$VM.xml" -JoinDomain:$false
    }
}