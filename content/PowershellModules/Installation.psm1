function Install-All {
    param(     
		[Parameter(Mandatory = $true)]
		[string]
		$rootPath,	   
        [Parameter(Mandatory = $true)]
		[string]
		$environmentConfigurationFilePath,
		[Parameter(Mandatory = $true)]
		[string]
		$productConfigurationFilePath
    )
    
	$configuration = Get-Configuration $environmentConfigurationFilePath $productConfigurationFilePath

	Install-FilePermissions $rootPath $configuration
    Install-Certificates $rootPath $configuration
	Install-Websites $rootPath $configuration
	Install-Services $rootPath $configuration
}

function Stop-All {
    param( 
		[Parameter(Mandatory = $true)]
		[string]
		$rootPath,		       
        [Parameter(Mandatory = $true)]
		[string]
		$environmentConfigurationFilePath,
		[Parameter(Mandatory = $true)]
		[string]
		$productConfigurationFilePath
    )
    
	$configuration = Get-Configuration $environmentConfigurationFilePath $productConfigurationFilePath

	Stop-Websites $configuration
	Stop-Services $rootPath $configuration
}

function Start-All {
    param(    
		[Parameter(Mandatory = $true)]
		[string]
		$rootPath,		    
        [Parameter(Mandatory = $true)]
		[string]
		$environmentConfigurationFilePath,
		[Parameter(Mandatory = $true)]
		[string]
		$productConfigurationFilePath
    )
    
	$configuration = Get-Configuration $environmentConfigurationFilePath $productConfigurationFilePath

	Start-Websites $configuration
	Start-Services $rootPath $configuration
}


function Uninstall-All {
    param( 
		[Parameter(Mandatory = $true)]
		[string]
		$rootPath,	       
        [Parameter(Mandatory = $true)]
		[string]
		$environmentConfigurationFilePath,
		[Parameter(Mandatory = $true)]
		[string]
		$productConfigurationFilePath
    )
    
	$configuration = Get-Configuration $environmentConfigurationFilePath $productConfigurationFilePath

	Uninstall-Websites $rootPath $configuration
	Uninstall-Services $rootPath $configuration
    Uninstall-Certificates $rootPath $configuration
	Uninstall-FilePermissions $rootPath $configuration
}

function Get-Metadata {
    param( 
        [Parameter(Mandatory = $true)]
        [string]
        $rootPath,         
        [Parameter(Mandatory = $true)]
        [string]
        $environmentConfigurationFilePath,
        [Parameter(Mandatory = $true)]
        [string]
        $productConfigurationFilePath
    )
    
    $configuration = Get-Configuration $environmentConfigurationFilePath $productConfigurationFilePath

    Get-MetadataForCertificates $rootPath $configuration
    Get-MetadataForWebsites $rootPath $configuration
    Get-MetadataForServices $rootPath $configuration
}
