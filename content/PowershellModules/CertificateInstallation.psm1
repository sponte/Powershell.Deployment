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

function Get-MetadataForCertificates {
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
        Get-MetadataForCertificate $rootPath $certificate
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
    $password=$certificateConfig.password 
    $Exportable=$certificateConfig.Exportable -eq $true
    $PersistKeySet=$certificateConfig.PersistKeySet -eq $true
    $MachineKeySet=$certificateConfig.MachineKeySet -eq $true
    $removeOnUninstall=$certificateConfig.removeOnUninstall -eq $true

    $certificate = Convert-Base64StringToX509Certificate -base64 $certificateContent -password $password -exportable $Exportable -persistKeySet $PersistKeySet -machineKeySet $MachineKeySet

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

function Get-MetadataForCertificate {
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

    $metaData = @{
        certificateName=$certificateName;
        certificateStore=$certificateStore;
        storeLocation=$storeLocation;
        thumbprint=$certificate.Thumbprint;
        notAfter=$certificate.NotAfter;
        notBefore=$certificate.NotBefore;
        issuer=$certificate.Issuer;
        subject=$certificate.Subject;
    }

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
        $binary = Get-Content $certificatePath -raw -Encoding Byte 
        return [convert]::ToBase64String($binary)
    }
    elseif ($certificate)
    {
        $tempFile = [IO.Path]::GetTempFileName()
        if ($password)
        {
            [system.IO.file]::WriteAllBytes($tempFile, $certificate.Export('PFX', $password))
        } else {
            [system.IO.file]::WriteAllBytes($tempFile, $certificate.Export('PFX'))
        }
        $binary = Get-Content $tempFile -raw -Encoding Byte 
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
        [boolean] $machineKeySet = $true,
        [boolean] $exportable = $true,
        [boolean] $persistKeySet = $true
    )

    if ($password)
    {
        $securePassword = convertto-securestring $password -asplaintext -force
    } else {
        $securePassword = $null 
    }

    $options = @()
    
    if ($machineKeySet){
        $options += "MachineKeySet"
    }

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

    $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite);

    if(!$store.Certificates.Contains($certificate)) {
        $store.Add($certificate)
    }

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

    if($store.Certificates.Contains($certificate)) {
        $store.Remove($certificate)
    }

    $store.Close();
}

function Get-X509Certificate {
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

    $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]'Read');
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
    $uniqueKeyContainerName = $privateKey.CspKeyContainerInfo.UniqueKeyContainerName
    $certificateFile = Get-ChildItem -path "$ENV:ProgramData\Microsoft\Crypto\RSA\MachineKeys" -Filter $uniqueKeyContainerName

    if(!$certificateFile) {
        throw "Could not find private key file at $("$ENV:ProgramData\Microsoft\Crypto\RSA\MachineKeys\$UniqueKeyContainerName")"
    }

    $certificatePermissions = $certificateFile.GetAccessControl("Access")
    
    $permissions | %{
        $permission = $_
        $username =  Format-AccountName $permission.Username

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
    }

    if ($certificatePermissions)
    {
        Set-Acl $certificateFile.FullName $certificatePermissions
    }
}