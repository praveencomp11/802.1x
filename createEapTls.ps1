$pstrEnableEapTlsXMLPath="network_profile.xml"
$piRetVal=@(0..10)
$piExitCode=0
$pstrServiceName="dot3svc"
$pstrServiceStartType="Automatic"
$pstrServiceStopType="Disabled"
$gstrInterfaceName="Local Area Connection"
$global:CAThumbprint=""
$global:ClientThumbprint=""

function validateRetValFromPrevCommand()
{
   if(!$?)    
	{
		return $False
	}
	else
	{
		return $True
	}	
   
}


$a=Import-PfxCertificate -FilePath C:\client_certificate.p12 -CertStoreLocation Cert:\CurrentUser\my -Password (ConvertTo -SecureString -String 'password' -AsPlainText -Force)
echo "Client certificate uploaded successfully"


$a=Import-Certificate -FilePath ca.der -CertStoreLocation Cert:\LocalMachine\Root
echo "CA certificate uploaded successfully"

$strNetshOutput=netsh lan add profile filename="network_profile.xml" interface="LAN Area Network"
if($strNetshOutput -Match "Error")
{	
	Write-host "Profile can't be added Successfully";
}
else
{
	Write-host "Profile added Successfully";	
	$strNetshOutput=netsh lan show profile
	if(($strNetshOutput -Match "Error"))
	{
			Write-host "Profile cann't added Successfully";	

	}
	else{
			Write-host "Profile added Successfully";	

	}
}