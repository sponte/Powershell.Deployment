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

function Get-MetadataForWebsites {
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
		Get-MetadataForWebsite $rootPath $site
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
	
	if(![string]::IsNullOrEmpty($appPoolConfig.account) -and $appPoolConfig.account -ne "NetworkService" -and $appPoolConfig.account -ne "Network Service" -and $appPoolConfig.account -ne "ApplicationPoolIdentity" -and $appPoolConfig.account -ne "Application Pool Identity" -and $appPoolConfig.account -ne "LocalService" -and $appPoolConfig.account -ne "Local Service" -and $appPoolConfig.account -ne "LocalSystem" -and $appPoolConfig.account -ne "Local System") {
		$appPool.processModel.username = Format-AccountName $appPoolConfig.account
		$appPool.processModel.password = $appPoolConfig.password
		$appPool.processModel.identityType = "SpecificUser"
	} else {
		if ($appPoolConfig.account -eq "ApplicationPoolIdentity" -or $appPoolConfig.account -eq "Application Pool Identity"){
			$appPool.processModel.identityType = "ApplicationPoolIdentity"
		} elseif ($appPoolConfig.account -eq "LocalSystem" -or $appPoolConfig.account -eq "Local System"){
			$appPool.processModel.identityType = "LocalSystem"
		} elseif ($appPoolConfig.account -eq "LocalService" -or $appPoolConfig.account -eq "Local Service"){
			$appPool.processModel.identityType = "LocalService"
		} else {
			$appPool.processModel.identityType = "NetworkService"
		}
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

				$ssl = $binding.ssl
				$thumbprint = $ssl.thumbprint

				$certificate = Get-ChildItem -Path cert:\LocalMachine -Recurse | ?{$_.Thumbprint -eq $thumbprint} | Select-Object -first 1 
				if (!$certificate){
					Throw "Cannot load certificate that matches thumbprint $thumbprint"
				}

				$privateKey = $certificate.PrivateKey

				if (!$privateKey) {
					Throw "Need access to private key for ssl encryption. Cannot access private key or does not contain private key for certificate with thumbprint $thumbprint"
				}

				$certificateFile = Get-Item -path "$ENV:ProgramData\Microsoft\Crypto\RSA\MachineKeys\*"  | where {$_.Name -eq $privateKey.CspKeyContainerInfo.UniqueKeyContainerName}
				$certificatePermissions = (Get-Item -Path $certificateFile.FullName).GetAccessControl("Access")

				$username = "Network Service"
				if(![string]::IsNullOrEmpty($siteConfig.appPool.account)) {
					$username = Format-AccountName $appPoolConfig.account
				}

				$permissionRule = $username,"Read","Allow"
				$accessRule = new-object System.Security.AccessControl.FileSystemAccessRule $permissionRule
				$certificatePermissions.AddAccessRule($accessRule)
				
				$permissionRule = $username,"FullControl","Allow"
				$accessRule = new-object System.Security.AccessControl.FileSystemAccessRule $permissionRule
				$certificatePermissions.AddAccessRule($accessRule)
				
				Set-Acl $certificateFile.FullName $certificatePermissions

				if(!(Test-Path "IIS:/SslBindings/$ip!$port")) {
					New-Item "IIS:/sslbindings/$ip!$port" -value $certificate
				} else {
					$sslBinding = Get-Item "IIS:/sslbindings/$ip!$port"

					if ($sslBinding.Thumbprint -eq $certificate.Thumbprint)
					{
						Write-Host "Certificate already installed in IIS"
					} elseif ($sslBinding.Sites.Count -eq 0) {
						Remove-Item "IIS:/sslbindings/$ip!$port"
					}
					else {
						Throw "Cannot use two different certificates on the same ip address $ip and port $port. The certificate thumbprints are: $($sslBinding.Thumbprint) and $($certificate.Thumbprint)"
					}
				}
			}
		}

		if([string]::IsNullOrEmpty($siteConfig.path)) {
			$siteConfig.path = $rootPath
		}

		if($siteConfig.path.StartsWith(".")) {
			$siteConfig.path = (Join-Path $rootPath $siteConfig.path.SubString(1, $siteConfig.path.Length - 1)).ToString()
		}
	
		Write-Log "Creating site $($siteConfig.name)"

		try {
			$site = New-Item `
 				-ApplicationPool $siteConfig.appPool.Name `
 				-PhysicalPath $siteConfig.path `
 				-Path "IIS:/Sites/$($siteConfig.Name)" `
 				-Bindings $bindings
		} catch [System.IndexOutOfRangeException] {
			Write-Log "Ensuring that IIS uses random site ids"
			Set-IisIncrementalSiteIdCreation -value $false

			Write-Log "Creating site $($siteConfig.name) Attempt #2"
			$site = New-Item `
				-ApplicationPool $siteConfig.appPool.Name `
				-PhysicalPath $siteConfig.path `
				-Path "IIS:/Sites/$($siteConfig.Name)" `
				-Bindings $bindings	
		}

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

function Get-MetadataForWebsite {
	param(
		[Parameter(Mandatory = $true)]
		[string]
		$rootPath,
		[Parameter(Mandatory = $true)]
		[System.XML.XMLElement]
		$siteConfig
	)

	$metaData = @()

	if(Test-Path "IIS:/Sites/$($siteConfig.name)") {
		if([string]::IsNullOrEmpty($siteConfig.path)) {
			$siteConfig.path = $rootPath
		}

		if($siteConfig.path.StartsWith(".")) {
			$siteConfig.path = (Join-Path $rootPath $siteConfig.path.SubString(1, $siteConfig.path.Length - 1)).ToString()
		}
	
		$binPath = Join-Path $rootPath "Bin"
		$hostAssemblyName = $siteConfig.name +  ".dll"
		$hostAssemblyFilePath = (Join-Path $binPath $hostAssemblyName).ToString()
		
		if(Test-Path $hostAssemblyFilePath)
		{
			$metaData += Get-MetaDataFromAssembly -assemblyFilePath $hostAssemblyFilePath 
		}
	}

	foreach($application in $siteConfig.applications.application) {
		if(!$application) { continue }
				
		if([string]::IsNullOrEmpty($application.physicalPath)) {
			$application.physicalPath = $rootPath
		}
		
		if($application.physicalPath.StartsWith(".")) {
			$application.physicalPath = (Join-Path $rootPath $application.physicalPath.SubString(1, $application.physicalPath.Length - 1)).ToString()
		}
		
		$binPath = Join-Path  $application.physicalPath "Bin"
						
		if($binPath.StartsWith(".")) {
			$binPath = (Join-Path $rootPath $binPath.SubString(1, $binPath.Length - 1)).ToString()
		}
		
		$hostAssemblyName = $application.alias +  ".dll"
		$hostAssemblyFilePath = (Join-Path $binPath $hostAssemblyName).ToString()
		
		if(Test-Path $hostAssemblyFilePath)
		{
			$metaData += Get-MetaDataFromAssembly -assemblyFilePath $hostAssemblyFilePath 
		}
	}

	return $metaData
}