# CreateISO

Why this custom ISO? Well, I want to (re)install a WDS server without any user input.
This one does exactly that, it installs and configures Windows Server. At the end, it downloads and executes a DSC script to install all roles.

## Requirements

An existing ISO file of Windows Server is required to create the ISO file. Windows Server 2016+ will do.

The autounattended.xml is placed in the root folder of the ISO. Windows setup will detect this file and use it.
