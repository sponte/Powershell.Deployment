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

    $webAdministrationAvailable = Get-Module WebAdministration -ListAvailable
    
	$configuration = Get-Configuration $environmentConfigurationFilePath $productConfigurationFilePath

	Install-FilePermissions $rootPath $configuration
    Install-Certificates $rootPath $configuration
    if ($webAdministrationAvailable)
    {
	   Install-Websites $rootPath $configuration
    }
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

    $webAdministrationAvailable = Get-Module WebAdministration -ListAvailable
    
	$configuration = Get-Configuration $environmentConfigurationFilePath $productConfigurationFilePath

    if ($webAdministrationAvailable)
    {
	   Stop-Websites $configuration
    }
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

    $webAdministrationAvailable = Get-Module WebAdministration -ListAvailable
    
	$configuration = Get-Configuration $environmentConfigurationFilePath $productConfigurationFilePath

    if ($webAdministrationAvailable)
    {
	   Start-Websites $configuration
    }
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

    $webAdministrationAvailable = Get-Module WebAdministration -ListAvailable
    
	$configuration = Get-Configuration $environmentConfigurationFilePath $productConfigurationFilePath

    if ($webAdministrationAvailable)
    {
	   Uninstall-Websites $rootPath $configuration
    }
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

    $webAdministrationAvailable = Get-Module WebAdministration -ListAvailable
    
    $configuration = Get-Configuration $environmentConfigurationFilePath $productConfigurationFilePath

    Get-MetadataForCertificates $rootPath $configuration
    if ($webAdministrationAvailable)
    {
    Get-MetadataForWebsites $rootPath $configuration
    }
    Get-MetadataForServices $rootPath $configuration
}
