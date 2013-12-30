$m = Get-Module WebAdministration -ListAvailable
if($m) {
	Import-Module $m.Name
} else {
	Write-Warning "WebAdministration module is not installed. It is not required for all installations but if you're trying to configure a Certificate your installation will fail"
}

function Install-Certificates {
    param( 
		[Parameter(Mandatory = $true)]       
		[string] 
		$rootPath,
		[Parameter(Mandatory = $true)]
		[System.XML.XMLDocument] 
		$configuration
	)
	
	foreach($certificate in @($configuration.configuration.certificates.certificate)) {
		if(!$certificate) { continue }
		Install-Certificate -rootPath $rootPath -certificateConfig $certificate
	}
}

function Uninstall-Certificates {
    param(        
 		[Parameter(Mandatory = $true)]       
		[string] 
		$rootPath,
		[Parameter(Mandatory = $true)]
		[System.XML.XMLDocument] 
		$configuration
	)
	
	foreach($certificate in @($configuration.configuration.certificates.certificate)) {
		if(!$certificate) { continue }
		Uninstall-Certificate $rootPath $certificate
	}
}

function Version-Certificates {
    param(        
        [Parameter(Mandatory = $true)]
        [string]
        $rootPath,     
        [Parameter(Mandatory = $true)]
        [System.XML.XMLDocument]
        $configuration
    )

	foreach($certificate in @($configuration.configuration.certificates.certificate)) {
		if(!$certificate) { continue }
		Version-Certificate $rootPath $certificate
	}
}

# Methods

function Uninstall-Certificate {
	param(
 		[Parameter(Mandatory = $true)]       
		[string] 
		$rootPath,
	    [Parameter(Mandatory = $true)]
		[System.XML.XMLElement]
		$certificateConfig
	)

	$certificateName = $certificateConfig.name
	$certificateContent = $certificateConfig.content

	$certificateStore=$certificateConfig.certificateStore
	$storeLocation=$certificateConfig.storeLocation
	$Exportable=$certificateConfig.Exportable -eq $true
	$password=$certificateConfig.password 
	$PersistKeySet=$certificateConfig.PersistKeySet -eq $true
	$removeOnUninstall=$certificateConfig.removeOnUninstall -eq $true

	$certificate = Convert-Base64StringToX509Certificate -base64 $certificateContent -password $password -exportable $Exportable -persistKeySet $PersistKeySet

	Remove-X509Certificate -certificate $certificate -certificateStore $certificateStore -storeLocation $storeLocation
}

function Install-Certificate {
	param(
		[Parameter(Mandatory = $true)]
		[string]
		$rootPath,
		[Parameter(Mandatory = $true)]
		[System.XML.XMLElement]
		$certificateConfig
	)
	
	UnInstall-Certificate $rootPath $certificateConfig

	$certificateName = $certificateConfig.name
	$certificateContent = $certificateConfig.content

	$certificateStore=$certificateConfig.certificateStore
	$storeLocation=$certificateConfig.storeLocation
	$Exportable=$certificateConfig.Exportable -eq $true
	$password=$certificateConfig.password 
	$PersistKeySet=$certificateConfig.PersistKeySet -eq $true
	$removeOnUninstall=$certificateConfig.removeOnUninstall -eq $true

	$certificate = Convert-Base64StringToX509Certificate -base64 $certificateContent -password $password -exportable $Exportable -persistKeySet $PersistKeySet

	Add-X509Certificate -certificate $certificate -certificateStore $certificateStore -storeLocation $storeLocation

	$certificatePermissions = @() 
	foreach($certificatePermission in @($certificateConfig.certificatePermissions.certificatePermission)) {
		$certificatePermissions += $certificatePermission
	}

    if ($certificatePermissions)
    {
	   Set-CertificatePermission -certificate $certificate -permissions $certificatePermissions
    }
}

function Version-Certificate {
	param(
		[Parameter(Mandatory = $true)]
		[string]
		$rootPath,
		[Parameter(Mandatory = $true)]
		[System.XML.XMLElement]
		$certificateConfig
	)

	$certificateName = $certificateConfig.name
	$certificateContent = $certificateConfig.content

	$certificateStore=$certificateConfig.certificateStore
	$storeLocation=$certificateConfig.storeLocation
	$Exportable=$certificateConfig.Exportable -eq $true
	$password=$certificateConfig.password 
	$PersistKeySet=$certificateConfig.PersistKeySet -eq $true
	$removeOnUninstall=$certificateConfig.removeOnUninstall -eq $true

	$certificate = Convert-Base64StringToX509Certificate -base64 $certificateContent -password $password -exportable $Exportable -persistKeySet $PersistKeySet

	$metaData = @(
		certificateName=$certificateName;
		certificateStore=$certificateStore;
		storeLocation=$storeLocation;
		thumbprint=$certificate.Thumbprint;
		notAfter=$certificate.NotAfter;
		notBefore=$certificate.NotBefore;
		issuer=$certificate.Issuer;
		subject=$certificate.Subject;
	)

	return $metaData
}

function Convert-X509CertificateToBase64String
{
    param(
        [string] $certificatePath,
        [System.Security.Cryptography.X509Certificates.X509Certificate2] $certificate,
		[string] $password
    )

    if ($certificatePath) {
        $binary = Get-Content $certificatePath -Encoding Byte
        return [convert]::ToBase64String($binary)
    }
    elseif ($certificate)
    {
		$tempFile = [IO.Path]::GetTempFileName()
		[system.IO.file]::WriteAllBytes($tempFile, $certificate.Export('PFX', $password))
        $binary = Get-Content $tempFile -Encoding Byte
        $null = Remove-Item $tempFile
        return [convert]::ToBase64String($binary)
    } else {
        return $null
    }
}

function Convert-Base64StringToX509Certificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $base64,
        [string] $password,
        [boolean] $exportable,
        [boolean] $persistKeySet
    )

    if ($password)
    {
        $securePassword = convertto-securestring $password -asplaintext -force
    } else {
        $securePassword = $null 
    }

	$options = @()
	if ($exportable){
		$options += "Exportable"
	}

	if ($persistKeySet){
		$options += "PersistKeySet"
	}

	$optionsText = $options -join ','

    if (!$optionsText)
    {
        $optionsText = ""
    }

    $binaryPfx = [convert]::FromBase64String($base64)
    $tempFile = [IO.Path]::GetTempFileName()
    Set-Content $tempFile -Value $binaryPfx -Encoding Byte

    if ($securePassword -and $optionsText)
    {
        $certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($tempFile, $securePassword, $optionsText)
    } elseif ($securePassword -and !$optionsText) {
        $certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($tempFile, $securePassword)
    } elseif (!$securePassword -and $optionsText) {
        $certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($tempFile, $null, $optionsText)
    } else {
        $certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($tempFile)
    }
    Remove-Item $tempFile
    $certificate
}

function Add-X509Certificate {
    [CmdletBinding()]
    param(
    	[System.Security.Cryptography.X509Certificates.X509Certificate2] $certificate,
    	[string] $certificateStore = 'My',
    	[string] $storeLocation = 'LocalMachine'
    )

    $storeLocation = [System.Security.Cryptography.X509Certificates.StoreLocation]$storeLocation;
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($certificateStore, $storeLocation);
    if (!$store) {
        Write-Warning "Unable to open -computerName '\\$computer\LocalComputer\$certificateStore\' certificate store.";
        continue;
    }

    $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]'ReadWrite');
    $store.Add($certificate);
    $store.Close();
}

function Remove-X509Certificate {
    [CmdletBinding()]
    param(
    	[System.Security.Cryptography.X509Certificates.X509Certificate2] $certificate,
    	[string] $certificateStore = 'My',
    	[string] $storeLocation = 'LocalMachine'
    )

    $storeLocation = [System.Security.Cryptography.X509Certificates.StoreLocation]$storeLocation;
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($certificateStore, $storeLocation);
    if (!$store) {
        Write-Warning "Unable to open -computerName '\\$computer\LocalComputer\$certificateStore\' certificate store.";
        continue;
    }

    $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]'ReadWrite');
    $store.Remove($certificate);
    $store.Close();
}

function Set-CertificatePermission {
	[CmdletBinding()]
    param(
    	[System.Security.Cryptography.X509Certificates.X509Certificate2] $certificate,
    	[object[]] $permissions
    )

	$privateKey = $certificate.PrivateKey
	$certificateFile = Get-Item -path "$ENV:ProgramData\Microsoft\Crypto\RSA\MachineKeys\*"  | where {$_.Name -eq $privateKey.CspKeyContainerInfo.UniqueKeyContainerName}
	$certificatePermissions = (Get-Item -Path $certificateFile.FullName).GetAccessControl("Access")
	
	$permissions | %{
		$permission = $_
		$username = $permission.Username

		if ($permission.read)
		{
			$permissionRule = $username,"Read","Allow"
			$accessRule = new-object System.Security.AccessControl.FileSystemAccessRule $permissionRule
			$certificatePermissions.AddAccessRule($accessRule)
		}

		if ($permission.fullControl)
		{
			$permissionRule = $username,"FullControl","Allow"
			$accessRule = new-object System.Security.AccessControl.FileSystemAccessRule $permissionRule
			$certificatePermissions.AddAccessRule($accessRule)
		}

		if ($permission.specialPermissions)
		{
			$permissionRule = $username,"SpecialPermissions","Allow"
			$accessRule = new-object System.Security.AccessControl.FileSystemAccessRule $permissionRule
			$certificatePermissions.AddAccessRule($accessRule)
		}
	}

	if ($certificatePermissions)
	{
		Set-Acl $certificateFile.FullName $certificatePermissions
	}
}