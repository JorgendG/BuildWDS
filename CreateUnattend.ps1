[xml]$Doc = New-Object System.Xml.XmlDocument
$dec = $Doc.CreateXmlDeclaration("1.0","UTF-8",$null)
$doc.AppendChild($dec)
$root = $doc.CreateNode("element","unattend",$null)
$root.SetAttribute( "xmlns", "urn:schemas-microsoft-com:unattend")
$penode = $doc.CreateNode("element","settings",$null)
$penode.SetAttribute( "pass", "windowsPE")
$winsetupNode = $doc.CreateNode("element","component",$null)
$winsetupNode.SetAttribute( "name", "Microsoft-Windows-Setup")
$winsetupNode.SetAttribute( "processorArchitecture", "amd64")
$winsetupNode.SetAttribute( "publicKeyToken", "31bf3856ad364e35")
$winsetupNode.SetAttribute( "language", "neutral")
$winsetupNode.SetAttribute( "versionScope", "nonSxS")
$winsetupNode.SetAttribute( "xmlns:wcm", "http://schemas.microsoft.com/WMIConfig/2002/State")
$winsetupNode.SetAttribute( "xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance")

$wdsnode = $doc.CreateNode("element","WindowsDeploymentServices",$null)
$loginnode = $doc.CreateNode("element","Login",$null)
$crednode = $doc.CreateNode("element","Credentials",$null)

$element = $doc.CreateElement( "Password")
$element.InnerText = "password"
$crednode.AppendChild($element)

$element = $doc.CreateElement( "Username")
$element.InnerText = "administrator"
$crednode.AppendChild($element)

$element = $doc.CreateElement( "Domain")
$element.InnerText = "wds01"
$crednode.AppendChild($element)

$loginnode.AppendChild( $crednode )
$wdsnode.AppendChild( $loginnode )

$imselectnode = $doc.CreateNode("element","ImageSelection",$null)
$instimagenode = $doc.CreateNode("element","InstallImage",$null)

$element = $doc.CreateElement( "ImageName")
$element.InnerText = "Windows Server 2016 SERVERSTANDARD"
$instimagenode.AppendChild($element)

$element = $doc.CreateElement( "ImageGroup")
$element.InnerText = "Windows Server 2016"
$instimagenode.AppendChild($element)

$insttonode = $doc.CreateNode("element","InstallImage",$null)

$element = $doc.CreateElement( "DiskID")
$element.InnerText = "0"
$insttonode.AppendChild($element)

$element = $doc.CreateElement( "PartitionID")
$element.InnerText = "3"
$insttonode.AppendChild($element)

$imselectnode.AppendChild( $instimagenode  )
$imselectnode.AppendChild( $insttonode  )
$wdsnode.AppendChild( $imselectnode )

$winsetupNode.AppendChild( $wdsnode )
$penode.AppendChild( $winsetupNode )
$root.AppendChild( $penode )
$doc.AppendChild( $root )
#<unattend xmlns="urn:schemas-microsoft-com:unattend">
#<settings pass="windowsPE">