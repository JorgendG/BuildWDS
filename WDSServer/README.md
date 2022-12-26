# WDSServer

Scripts to configure the server as a WDS en Desired State Configuration Pull Server.

InstallWDS.ps1 is called during the RunSynchronous steps of the autounattended.xml.

Creates a local user, creates a new unattended.xml file, download files and creates a scheduled task.

Looking at it, I should merge move parts of the script and end up with only 2 scripts.
Use InstallWDS.ps1 just to create the scheduled task.

The scheduled task is needed, I can't perform certains PowerShell commands during the RunSynchronous phase of setup.
