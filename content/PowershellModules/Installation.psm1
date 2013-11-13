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
}

