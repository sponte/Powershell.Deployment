$m = Get-Module WebAdministration -ListAvailable
if($m) {
	Import-Module $m.Name
} else {
	Write-Warning "WebAdministration module is not installed. It is not required for all installations but if you're trying to configure a website your installation will fail"
}

function Install-Websites {
 param( 
		[Parameter(Mandatory = $true)]       
		[string] 
		$rootPath,
		[Parameter(Mandatory = $true)]
		[System.XML.XMLDocument] 
		$configuration
	)
	
	foreach($site in @($configuration.configuration.sites.site)) {
		if(!$site) { continue }
		Install-Website -rootPath $rootPath -siteConfig $site
	}
}

function Uninstall-Websites {
 param(        
 		[Parameter(Mandatory = $true)]       
		[string] 
		$rootPath,
		[Parameter(Mandatory = $true)]
		[System.XML.XMLDocument] 
		$configuration
	)
	
	foreach($site in @($configuration.configuration.sites.site)) {
		if(!$site) { continue }
		Uninstall-Website $rootPath $site
	}
}

function Stop-Websites {
 param(        
		[Parameter(Mandatory = $true)]
		[System.XML.XMLDocument] 
		$configuration
	)
	
	foreach($site in @($configuration.configuration.sites.site)) {
		if(!$site) { continue }
		Stop-Website $site
	}
}

function Start-Websites {
 param(        
	   [Parameter(Mandatory = $true)]
       [System.XML.XMLDocument] 
	   $configuration
	)
	
	foreach($site in @($configuration.configuration.sites.site)) {
		if(!$site) { continue }
		Start-Website $site
	}
}

# Methods

function Uninstall-Website {
	param(
 		[Parameter(Mandatory = $true)]       
		[string] 
		$rootPath,
	    [Parameter(Mandatory = $true)]
		[System.XML.XMLElement]
		$siteConfig
	)

	# uninstall any custom .net installers that may be in the host assembly
	$binPath = Join-Path $rootPath "Bin"
	$hostAssemblyName = $siteConfig.name +  ".dll"
	$hostAssemblyFilePath = (Join-Path $binPath $hostAssemblyName).ToString()
	
	if(Test-Path $hostAssemblyFilePath)
	{
		Uninstall-Util $hostAssemblyFilePath
	} else	{
		Write-Log "Can not find assembly $hostAssemblyFilePath so not running uninstall-util"
	}
	
	foreach($application in @($siteConfig.applications.application)) {
		if(!$application) { continue }

		

		# uninstall any custom .net installers that may be in the host assembly
		$binPath = Join-Path  $application.physicalPath "Bin"
		
		if($binPath.StartsWith(".")) {
			$binPath = (Join-Path $rootPath $binPath.SubString(1, $binPath.Length - 1)).ToString()
		}
		
		$hostAssemblyName = $application.alias +  ".dll"
		$hostAssemblyFilePath = (Join-Path $binPath $hostAssemblyName).ToString()
		
		if(Test-Path $hostAssemblyFilePath)
		{
			Uninstall-Util $hostAssemblyFilePath
		} else	{
			Write-Log "Can not find assembly $hostAssemblyFilePath so not running uninstall-util"
		}

		if(Test-Path "IIS:/Sites/$($siteConfig.name)/$($application.alias)") {
			Write-Log "Removing site $($siteConfig.name)/$($application.alias)"
			Remove-WebApplication $application.alias -Site $siteConfig.Name -Verbose
		}

		if(Test-Path "IIS:\AppPools\$($application.AppPool.Name)") {
			Write-Log "Removing application pool $($application.AppPool.Name)"
			Remove-WebAppPool $application.AppPool.Name -Verbose
		}

	}
	
	$siteSafeToRemove= ($siteConfig.containerOnly -ne "true")

	if((Test-Path "IIS:/Sites/$($siteConfig.name)") -and ($siteConfig.containerOnly -eq "true")) {
		$path = "IIS:/Sites/$($siteConfig.name)"
		$apps = (Get-ChildItem -Path $path) | ?{ $_.ElementTagName -eq "application" }
		$siteSafeToRemove= $apps -eq $null
	}

	if(Test-Path "IIS:/Sites/$($siteConfig.name)") {
		if($siteSafeToRemove) {
			Write-Log "site $($siteConfig.name) already exists, removing"
			Remove-Website $siteConfig.name -Verbose
		} else {
			Write-Log "Site $($siteConfig.name) is not safe to remove as it contains other applications"
		}
	}

	if(Test-Path "IIS:/AppPools/$($siteConfig.appPool.name)") {
		if($siteSafeToRemove) {
			Write-Log "AppPool $($siteConfig.appPool.name) already exists, removing"
			Remove-WebAppPool $siteConfig.name -Verbose
		} else {
			Write-Log "ApplicationPool $($siteConfig.appPool.name) is not safe to remove as it contains other applications"
		}
	}

		
}

function Stop-Website {
	param(
        [Parameter(Mandatory = $true)]
		[System.XML.XMLElement]
		$siteConfig
	)
	
	if($siteConfig.containerOnly -ne "true") {
		if (Test-Path "IIS:\Sites\$($siteConfig.name)")
		{
			$site = Get-Item "IIS:\Sites\$($siteConfig.name)"
			if ($site.state -ne "stopped")
			{
				$site.Stop()
			}
		}

		if (Test-Path "IIS:\AppPools\$($siteConfig.AppPool.Name)")
		{
			$appPool = Get-Item "IIS:\AppPools\$($siteConfig.AppPool.Name)"
			if ($appPool.state -ne "stopped")
			{
				$appPool.Stop()
			}
		}
	}

	foreach($application in @($siteConfig.applications.application)) {
		if(!$application) { continue }
		if (Test-Path "IIS:\AppPools\$($application.AppPool.Name)")
		{
			$appPool = Get-Item "IIS:\AppPools\$($application.AppPool.Name)"
			if ($appPool.state -ne "stopped")
			{
				$appPool.Stop()
			}
		}
	}
}

function Start-Website {
	param(
        [Parameter(Mandatory = $true)]
		[System.XML.XMLElement]
		$siteConfig
	)
	
	if($siteConfig.containerOnly -ne "true") {
		$site = Get-Item "IIS:\Sites\$($siteConfig.name)"
		if ($site.state -ne "started")
		{
			$site.Start()
		}

		$appPool = Get-Item "IIS:\AppPools\$($siteConfig.AppPool.Name)"
		$appPool.Start()
		if ($appPool.state -ne "started")
		{
			$appPool.Start()
		}
	}

	foreach($application in @($siteConfig.applications.application)) {
		if(!$application) { continue }
		$appPool = Get-Item "IIS:\AppPools\$($application.AppPool.Name)"
		if ($appPool.state -ne "started")
		{
			$appPool.Start()
		}
	}
}

function Install-ApplicationPool {
	param (
        [Parameter(Mandatory = $true)]
		[System.XML.XMLElement]
		$appPoolConfig
	)
	
	if(Test-Path "IIS:/AppPools/$($appPoolConfig.name)") {
		Write-Log "The app pool $($appPoolConfig.name) already exists, removing"
		Remove-WebAppPool $appPoolConfig.Name
	}
	
	Write-Log "Creating applicationPool $($appPoolConfig.name)"
	$appPool = New-WebAppPool -Name $appPoolConfig.name
	
	$appPool.enable32BitAppOnWin64 = $appPoolConfig.enable32Bit
	$appPool.managedRuntimeVersion = $appPoolConfig.frameworkVersion
	$appPool.managedPipelineMode = $appPoolConfig.managedPipelineMode
	
	if(![string]::IsNullOrEmpty($appPoolConfig.account)) {
		$appPool.processModel.username = Format-AccountName $appPoolConfig.account
		$appPool.processModel.password = $appPoolConfig.password
		$appPool.processModel.identityType = "SpecificUser"
	} else {
		$appPool.processModel.identityType = "NetworkService"
	}

	$appPool | Set-Item

	Write-Log "AppPool properties"
	Write-Log $appPoolConfig.properties.property
	foreach($property in $appPoolConfig.properties.property) {
		if($property -eq $null) { continue }

		Write-Log "[AppPool $($appPoolConfig.name)] Setting property $($property.Path) = $($property.value)"
		Set-ItemProperty "IIS:\AppPools\$($appPoolConfig.name)" -Name $property.Path -Value $property.Value
	}
}

function Install-Website {
	param(
		[Parameter(Mandatory = $true)]
		[string]
		$rootPath,
		[Parameter(Mandatory = $true)]
		[System.XML.XMLElement]
		$siteConfig
	)
	
	UnInstall-WebSite $rootPath $siteConfig

	# for each of the app, check whether the are the only apps installed
		
	if(-not(Test-Path "IIS:/Sites/$($siteConfig.name)")) {
		$appPoolConfig = $siteConfig.appPool
		
		Install-ApplicationPool $siteConfig.appPool
	
		$bindings = @()
		foreach($binding in $siteConfig.bindings.binding) {
			if(!$binding) { continue }

			$bindings += @{ protocol=$binding.protocol;bindingInformation=$binding.information }
			if($binding.protocol -eq "https") {
		
				$arr = $binding.information.Split(":")		

				$ip = $arr[0]
				$port = $arr[1]

				if($ip -eq "*") {
					$ip = "0.0.0.0"
				}

				if(Test-Path "IIS:/SslBindings/$ip!$port") {
					Remove-Item "IIS:/SslBindings/$ip!$port" -Force
				}
			
				$ssl = $binding.ssl
			
				$ssl.thumbprint | new-Item "IIS:/SslBindings/$ip!$port"
			}
		}

		if([string]::IsNullOrEmpty($siteConfig.path)) {
			$siteConfig.path = $rootPath
		}

		if($siteConfig.path.StartsWith(".")) {
			$siteConfig.path = (Join-Path $rootPath $siteConfig.path.SubString(1, $siteConfig.path.Length - 1)).ToString()
		}
	
		Write-Log "Creating site $($siteConfig.name)"
		$site = New-Item `
					-ApplicationPool $siteConfig.appPool.Name `
					-PhysicalPath $siteConfig.path `
					-Path "IIS:/Sites/$($siteConfig.Name)" `
					-Bindings $bindings

		$bindingProtocols = ($siteConfig.bindings.binding | Select -ExpandProperty protocol) -join ","
		Set-ItemProperty "IIS:/Sites/$($siteConfig.Name)" -Name enabledProtocols -value $bindingProtocols

		# install any custom .net installers that may be in the host assembly
		$binPath = Join-Path $rootPath "Bin"
		$hostAssemblyName = $siteConfig.name +  ".dll"
		$hostAssemblyFilePath = (Join-Path $binPath $hostAssemblyName).ToString()
		
		if(Test-Path $hostAssemblyFilePath)
		{
			Install-Util $hostAssemblyFilePath
		} else	{
			Write-Log "Can not find assembly $hostAssemblyFilePath so not running install-util"
		}

	}
	
	foreach($application in $siteConfig.applications.application) {
		if(!$application) { continue }
		
		Install-ApplicationPool $application.appPool
		
		if([string]::IsNullOrEmpty($application.physicalPath)) {
			$application.physicalPath = $rootPath
		}
		
		if($application.physicalPath.StartsWith(".")) {
			$application.physicalPath = (Join-Path $rootPath $application.physicalPath.SubString(1, $application.physicalPath.Length - 1)).ToString()
		}
		
		Write-Log "Creating web application $($application.alias)" -ForegroundColor Green
		New-WebApplication `
			-ApplicationPool $application.appPool.name `
			-Name $application.alias `
			-PhysicalPath $application.physicalPath `
			-Site $site.name `
			-Force

		$bindingProtocols = ($siteConfig.bindings.binding | Select -ExpandProperty protocol) -join ","
		Set-ItemProperty "IIS:/Sites/$($siteConfig.Name)/$($application.alias)" -Name enabledProtocols -value $bindingProtocols

		foreach($virtualDirectory in $application.virtualDirectories.virtualDirectory) {
			if(!$virtualDirectory) { continue }
		
			if($virtualDirectory.physicalPath.StartsWith(".")) {
				$virtualDirectory.physicalPath = (Join-Path $rootPath $virtualDirectory.physicalPath.SubString(1, $virtualDirectory.physicalPath.Length - 1)).ToString()
			}

			Write-Log "Creating $($virtualDirectory.alias) virtualDirectory under $($site.name)\$($application.alias)"
		
			New-WebVirtualDirectory -Name $virtualDirectory.alias `
				-PhysicalPath $virtualDirectory.physicalPath `
				-Site "$($site.name)\$($application.alias)" `
				-Force
		}

		# install any custom .net installers that may be in the host assembly
		$binPath = Join-Path  $application.physicalPath "Bin"
						
		if($binPath.StartsWith(".")) {
			$binPath = (Join-Path $rootPath $binPath.SubString(1, $binPath.Length - 1)).ToString()
		}
		
		$hostAssemblyName = $application.alias +  ".dll"
		$hostAssemblyFilePath = (Join-Path $binPath $hostAssemblyName).ToString()
		
		if(Test-Path $hostAssemblyFilePath)
		{
			Install-Util $hostAssemblyFilePath
		} else	{
			Write-Log "Can not find assembly $hostAssemblyFilePath so not running install-util"
		}
	}
	
	foreach($virtualDirectory in $siteConfig.virtualDirectories.virtualDirectory) {
		if(!$virtualDirectory) { continue }
		
		if($virtualDirectory.physicalPath.StartsWith(".")) {
			$virtualDirectory.physicalPath = (Join-Path $rootPath $virtualDirectory.physicalPath.SubString(1, $virtualDirectory.physicalPath.Length - 1)).ToString()
		}

		Write-Log "Creating $($virtualDirectory.alias) virtualDirectory"
		
		New-WebVirtualDirectory -Name $virtualDirectory.alias `
			-PhysicalPath $virtualDirectory.physicalPath `
			-Site $site.name `
			-Force
	}
}