
function Install-Services {
 param(  
		[Parameter(Mandatory = $true)]
		[string]
		$rootPath,	   
        [Parameter(Mandatory = $true)]
		[System.XML.XMLDocument]
		$configuration
    )

	foreach($service in @($configuration.configuration.services.NServiceBus)) {
		if(!$service) { continue }
		Install-NserviceBus -rootPath $rootPath -serviceConfig $service
	}

	foreach($service in @($configuration.configuration.services.WindowsService)) {
		if(!$service) { continue }
		Install-WindowsService -rootPath $rootPath -serviceConfig $service
	}

	foreach($service in @($configuration.configuration.services.TopshelfService)) {
		if(!$service) { continue }
		Install-TopshelfService -rootPath $rootPath -serviceConfig $service
	}

	foreach($service in @($configuration.configuration.services.JavaService)) {
		if(!$service) { continue }
		Install-JavaService -rootPath $rootPath -serviceConfig $service
	}
}

function Uninstall-Services {
 param(        
		[Parameter(Mandatory = $true)]
		[string]
		$rootPath,	   
        [Parameter(Mandatory = $true)]
		[System.XML.XMLDocument]
		$configuration
    )
	
	foreach($service in @($configuration.configuration.services.NServiceBus)) {
		if(!$service) { continue }
		Uninstall-NserviceBus -rootPath $rootPath -serviceConfig $service
	}

	foreach($service in @($configuration.configuration.services.WindowsService)) {
		if(!$service) { continue }
		Uninstall-WindowsService -rootPath $rootPath -serviceConfig $service
	}	

	foreach($service in @($configuration.configuration.services.TopshelfService)) {
		if(!$service) { continue }
		Uninstall-TopshelfService -rootPath $rootPath -serviceConfig $service
	}	

	foreach($service in @($configuration.configuration.services.JavaService)) {
		if(!$service) { continue }
		#we don't want to reboot on every uninstall so use sc delete way
		Uninstall-WindowsService -rootPath $rootPath -serviceConfig $service
	}	
}

function Stop-Services {
 param(        
		[Parameter(Mandatory = $true)]
		[string]
		$rootPath,	   
        [Parameter(Mandatory = $true)]
		[System.XML.XMLDocument]
		$configuration
    )

	foreach($service in @($configuration.configuration.services.NServiceBus)) {
		if(!$service) { continue }
		Stop-WindowsService $service
	}

	foreach($service in @($configuration.configuration.services.WindowsService)) {
		if(!$service) { continue }
		Stop-WindowsService $service
	}

	foreach($service in @($configuration.configuration.services.TopshelfService)) {
		if(!$service) { continue }
		Stop-WindowsService $service
	}	

	foreach($service in @($configuration.configuration.services.JavaService)) {
		if(!$service) { continue }
		Stop-WindowsService $service
	}	
}

function Start-Services {
 param(        
		[Parameter(Mandatory = $true)]
		[string]
		$rootPath,	   
        [Parameter(Mandatory = $true)]
		[System.XML.XMLDocument]
		$configuration
    )

	foreach($service in @($configuration.configuration.services.NServiceBus)) {
		if(!$service) { continue }
		Start-WindowsService $service
	}

	foreach($service in @($configuration.configuration.services.WindowsService)) {
		if(!$service) { continue }
		Start-WindowsService $service
	}	

	foreach($service in @($configuration.configuration.services.TopshelfService)) {
		if(!$service) { continue }
		Start-WindowsService $service
	}	

	foreach($service in @($configuration.configuration.services.JavaService)) {
		if(!$service) { continue }
		Start-WindowsService $service
	}	
}

function Get-MetadataForServices {
 param(        
        [Parameter(Mandatory = $true)]
        [string]
        $rootPath,     
        [Parameter(Mandatory = $true)]
        [System.XML.XMLDocument]
        $configuration
    )

    foreach($service in @($configuration.configuration.services.NServiceBus)) {
        if(!$service) { continue }
        Get-MetadataForNserviceBus $service
    }

    foreach($service in @($configuration.configuration.services.WindowsService)) {
        if(!$service) { continue }
        Get-MetadataForWindowsService $service
    }   

    foreach($service in @($configuration.configuration.services.TopshelfService)) {
        if(!$service) { continue }
        Get-MetadataForTopshelfService $service
    }   

    foreach($service in @($configuration.configuration.services.JavaService)) {
        if(!$service) { continue }
        Get-MetadataForJavaService $service
    }   
}

# Methods

function Install-WindowsService {
	param(
		[Parameter(Mandatory = $true)]
		[string]
		$rootPath,	   
        [Parameter(Mandatory = $true)]
		[System.XML.XMLElement]
		$serviceConfig
	)

	if($serviceConfig.account) {
		$serviceConfig.account = Format-AccountName $serviceConfig.account
	}

	$service = GetService $serviceConfig.name
	if ($service -ne $null )
	{
		Uninstall-WindowsService `
			-rootPath $rootPath `
			-serviceConfig $serviceConfig			
	}	

	# install any custom .net installers that may be in the host assembly		
	$hostAssemblyName = $serviceConfig.name +  ".dll"
	$hostAssemblyFilePath = (Join-Path $rootPath $hostAssemblyName).ToString()

	if(Test-Path $hostAssemblyFilePath)
	{
		Install-Util $hostAssemblyFilePath
	} else	{
		Write-Log "Can not find assembly $hostAssemblyFilePath so not running install-util"
	}	

	# install the service

	$serviceStartUpType = "delayed-auto"

	$binPath = $serviceConfig.path

	if($binPath.StartsWith(".")) {
		$binPath = (Join-Path $rootPath $binPath.SubString(1, $binPath.Length - 1)).ToString()
	}

	$serviceContainer = $serviceConfig.serviceContainer

	if ($serviceContainer -eq 'srvany') {
		$servicePath = Join-Path $rootPath "deployment\PowershellModules\Tools\srvany.exe"
		
		if (split-path $binPath) {
			$destinationPath = "$(split-path $binPath)\srvany.exe"
		} else {
			$destinationPath =	"$rootPath\srvany.exe"
		}
		if (-not (Test-Path $destinationPath)) {
			copy-item $servicePath $destinationPath
		}
		$servicePath = $destinationPath
	} elseif ($serviceContainer -eq 'nssm') {
		$servicePath = Join-Path $rootPath "deployment\PowershellModules\Tools\nssm.exe"

		if (split-path $binPath) {
			$destinationPath = "$(split-path $binPath)\nssm.exe"
		} else {
			$destinationPath =	"$rootPath\nssm.exe"
		} 
		if (-not (Test-Path $destinationPath)) {
			copy-item $servicePath $destinationPath
		}		
		$servicePath = $destinationPath		
	} else {
		$servicePath = "`"$binPath`""

		if ($serviceConfig.arguments) {
			$servicePath = "$servicePath $($serviceConfig.arguments)"
		}
	}

	if([string]::IsNullOrEmpty($serviceConfig.account) -eq $true) {
		New-Service -binaryPathName $servicePath -name $serviceConfig.name -displayName $serviceConfig.displayName -startupType Automatic
	} else {
		$secretPassword = $serviceConfig.password | ConvertTo-SecureString -AsPlainText -Force
		$PSCredentials = New-Object System.Management.Automation.PSCredential ($serviceConfig.account, $secretPassword)

		New-Service -binaryPathName $servicePath -name $serviceConfig.name -credential $PSCredentials -displayName $serviceConfig.displayName -startupType Automatic		
	}

	if ($serviceContainer -eq 'srvany' -or $serviceContainer -eq 'nssm') {	
		New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\services\$($serviceConfig.name)" -Name "Parameters" –Force
		New-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\services\$($serviceConfig.name)\Parameters" -Name "Application" -Value "$binPath" -Force
		if ($serviceConfig.arguments) {
			New-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\services\$($serviceConfig.name)\Parameters" -Name "AppParameters" -Value "$($serviceConfig.arguments)" -Force
		} else {
			if ((Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\services\$($serviceConfig.name)\Parameters").AppParameters -ne $null){
				Remove-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\services\$($serviceConfig.name)\Parameters" -Name "AppParameters"
			}
		}
	}

	if ($serviceConfig.description) {
		$configureServiceDescription = "sc.exe description  $($serviceConfig.name) ""$($serviceConfig.description)"" "
		Invoke-Expression -Command $configureServiceDescription -ErrorAction Stop
	}

	$dependsOnServices = '/'

	if ($serviceConfig.dependsOnServices.dependsOnService -ne $null) {
	    foreach($dependsOnService in @($serviceConfig.dependsOnServices.dependsOnService)) {
	        if(!$dependsOnService) { continue }
	        if ($dependsOnServices -eq '/') {
				$dependsOnServices = $dependsOnService.serviceName
			} else {
				$dependsOnServices += "/$($dependsOnService.serviceName)"
			}
	    }   
    } 

	$configureServiceStartup = "sc.exe config $($serviceConfig.name) depend= $dependsOnServices"
	Invoke-Expression -Command $configureServiceStartup -ErrorAction Stop

	$configureServiceStartup = "sc.exe config $($serviceConfig.name) start= $serviceStartUpType"
	Invoke-Expression -Command $configureServiceStartup -ErrorAction Stop
}

function Install-NServiceBus {
	param(
		[Parameter(Mandatory = $true)]
		[string]
		$rootPath,	   
        [Parameter(Mandatory = $true)]
		[System.XML.XMLElement]
		$serviceConfig
	)

	if($serviceConfig.account) {
		$serviceConfig.account = Format-AccountName $serviceConfig.account
	}

	$service = GetService $serviceConfig.name
	if ($service -ne $null )
	{
		Uninstall-NserviceBus `
			-rootPath $rootPath `
			-serviceConfig $serviceConfig			
	}

	# install any custom .net installers that may be in the host assembly		
	$hostAssemblyName = $serviceConfig.name +  ".dll"
	$hostAssemblyFilePath = (Join-Path $rootPath $hostAssemblyName).ToString()

	if(Test-Path $hostAssemblyFilePath)
	{
		Install-Util $hostAssemblyFilePath
	} else	{
		Write-Log "Can not find assembly $hostAssemblyFilePath so not running install-util"
	}

	# install the service

	$serviceStartUpType = "delayed-auto"

	if ([string]::IsNullOrEmpty($serviceConfig.serviceStartupType) -eq $false)
	{
		$serviceStartUpType = $serviceConfig.serviceStartupType
	}

	$profiles = @($serviceConfig.profiles.profile) -join " "

	if([string]::IsNullOrEmpty($serviceConfig.account) -eq $true) {
		Write-Log "Installing service with no username"
		&$rootPath\NServiceBus.Host.exe $profiles /install /servicename:"$($serviceConfig.name)" /displayname:"$($serviceConfig.displayName)" 
		if($LASTEXITCODE -ne 0) {
			throw "NServiceBus.Host.exe raised an error, please review log messages"
		}
	} else {
		Write-Log "Installing service with username $($serviceConfig.account)"
		&$rootPath\NServiceBus.Host.exe $profiles /install /servicename:"$($serviceConfig.name)" /displayname:"$($serviceConfig.displayName)" /username:"$($serviceConfig.account)" /password:"$($serviceConfig.password)" 
		if($LASTEXITCODE -ne 0) {
			throw "NServiceBus.Host.exe raised an error, please review log messages"
		}

		Write-Log "Setting MSMQ permissions for user $($serviceConfig.account)"
		[Reflection.Assembly]::LoadWithPartialName( "System.Messaging" )
		$msmq = [System.Messaging.MessageQueue]
		$machineName = gc env:computername
		$privateQueues = $msmq::GetPrivateQueuesByMachine($machineName)
		$rights = [System.Messaging.MessageQueueAccessRights]::DeleteMessage -bor
				  [System.Messaging.MessageQueueAccessRights]::DeleteJournalMessage -bor
				  [System.Messaging.MessageQueueAccessRights]::PeekMessage -bor
				  [System.Messaging.MessageQueueAccessRights]::WriteMessage -bor
				  [System.Messaging.MessageQueueAccessRights]::DeleteMessage
        
		foreach($privateQueue in $privateQueues){	
			foreach ($queue in @($serviceConfig.queues.queue))
			{
				if(!$queue) { continue }

				if ($privateQueue.QueueName -match $queue){
					Write-Log "Setting permissions for: $($privateQueue.QueueName)"
					$privateQueue.SetPermissions($serviceConfig.account, $rights, [System.Messaging.AccessControlEntryType]::Set)
					break
				}
			}
		}
	}

	$configureServiceStartup = "sc.exe config $($serviceConfig.name) start= $serviceStartUpType"
	Invoke-Expression -Command $configureServiceStartup -ErrorAction Stop
}


function Install-TopshelfService {
	param(
		[Parameter(Mandatory = $true)]
		[string]
		$rootPath,	   
        [Parameter(Mandatory = $true)]
		[System.XML.XMLElement]
		$serviceConfig
	)

	if($serviceConfig.account) {
		$serviceConfig.account = Format-AccountName $serviceConfig.account
	}

	$service = GetService $serviceConfig.name
	if ($service -ne $null )
	{
		Uninstall-TopshelfService `
			-rootPath $rootPath `
			-serviceConfig $serviceConfig			
	}	

	# install any custom .net installers that may be in the host assembly		
	$hostAssemblyName = $serviceConfig.name +  ".dll"
	$hostAssemblyFilePath = (Join-Path $rootPath $hostAssemblyName).ToString()

	if(Test-Path $hostAssemblyFilePath)
	{
		Install-Util $hostAssemblyFilePath
	} else	{
		Write-Log "Can not find assembly $hostAssemblyFilePath so not running install-util"
	}	

	# install the service

	$serviceStartUpType = "delayed-auto"

	$binPath = $serviceConfig.path

	if($binPath.StartsWith(".")) {
		$binPath = (Join-Path $rootPath $binPath.SubString(1, $binPath.Length - 1)).ToString()
	}

	$servicePath = $binPath

	$arguments = @()
	$arguments += "install"
	$arguments += "-servicename `"$($serviceConfig.Name)`""
	$arguments += "-displayname `"$($serviceConfig.DisplayName)`""

	if(! [string]::IsNullOrEmpty($serviceConfig.account)) {
		$arguments += "-username `"$($serviceConfig.account)`""
		$arguments += "-password `"$($serviceConfig.password)`""
	}

	if($serviceConfig.serviceStartupType -eq "delayed-auto") {
		$arguments += "--delayed"
	}
	Write-Host "$binPath $($arguments -join " ")"
	Start-Process $binPath -Argument $arguments -Wait
}

function Install-JavaService {
	param(
		[Parameter(Mandatory = $true)]
		[string]
		$rootPath,	   
        [Parameter(Mandatory = $true)]
		[System.XML.XMLElement]
		$serviceConfig
	)

	if($serviceConfig.account) {
		$serviceConfig.account = Format-AccountName $serviceConfig.account
	}

	$service = GetService $serviceConfig.name
	if ($service -ne $null )
	{
		Uninstall-JavaService `
			-rootPath $rootPath `
			-serviceConfig $serviceConfig			
	}	

	# install the service

	$serviceStartUpType = "delayed-auto"

	if ([string]::IsNullOrEmpty($serviceConfig.serviceStartupType) -eq $false)
	{
		$serviceStartUpType = $serviceConfig.serviceStartupType
	}

	$binPath = $serviceConfig.path

	if($binPath.StartsWith(".")) {
		$binPath = (Join-Path $rootPath $binPath.SubString(1, $binPath.Length - 1)).ToString()
	}

	$servicePath = Join-Path $rootPath "deployment\PowershellModules\Tools\Prunmgr.exe"
	$destinationPath = "$(split-path $binPath)\$($serviceConfig.Name)w.exe"
	if (-not (Test-Path $destinationPath)) {
		copy-item $servicePath $destinationPath
	}
	$servicePath = $destinationPath	

	$servicePath = Join-Path $rootPath "deployment\PowershellModules\Tools\prunsrv.exe"
	$destinationPath = "$(split-path $binPath)\$($serviceConfig.Name).exe"
	if (-not (Test-Path $destinationPath)) {
		copy-item $servicePath $destinationPath
	}
	$servicePath = $destinationPath

	$arguments = @()
	$arguments += "//IS//$($serviceConfig.Name)"
	$arguments += "--Classpath=`"$binPath`""
	$arguments += "--DisplayName=`"$($serviceConfig.DisplayName)`""
	$arguments += "--Install=$destinationPath"
	$arguments += "--Jvm=auto"

	# Start
	$arguments += "--StartMode=$($serviceConfig.StartMode)"
	$arguments += "--StartClass=$($serviceConfig.StartClass)"
	$arguments += "--StartMethod=$($serviceConfig.StartMethod)"
	if ($serviceConfig.StartParams)
	{
		$arguments += "--StartParams=$($serviceConfig.StartParams)"
	}
	
	# Stop
	$arguments += "--StopMode=$($serviceConfig.StopMode)"
	$arguments += "--StopClass=$($serviceConfig.StopClass)"
	$arguments += "--StopMethod=$($serviceConfig.StopMethod)"
	if ($serviceConfig.StopParams)
	{
		$arguments += "--StopParams=$($serviceConfig.StopParams)"
	}

	if(![string]::IsNullOrEmpty($serviceConfig.account)) {
		$arguments += "--User=`"$($serviceConfig.account)`""
		$arguments += "--Password=`"$($serviceConfig.password)`""
		$arguments += "--ServiceUser=`"$($serviceConfig.account)`""
		$arguments += "--ServicePassword=`"$($serviceConfig.password)`""
	}

	Write-Host "$servicePath $($arguments -join " ")"
	Start-Process $servicePath -Argument $arguments -Wait

	$configureServiceStartup = "sc.exe config $($serviceConfig.name) start= $serviceStartUpType"
	Invoke-Expression -Command $configureServiceStartup -ErrorAction Stop
}

function Uninstall-WindowsService {
	param(
		[Parameter(Mandatory = $true)]
		[string]
		$rootPath,	   
        [Parameter(Mandatory = $true)]
		[System.XML.XMLElement]
		$serviceConfig
	)

	$service = GetService $serviceConfig.name
	if ($service)
	{
		Stop-WindowsService -serviceConfig $serviceConfig

		# uninstall service	

		$removeService = "sc.exe delete $($serviceConfig.name)"
		Invoke-Expression -Command $removeService -ErrorAction Stop

		$MaximumAttempts = 10
		$Attempt = 0
		while ((get-service | ?{$_.Name -eq $serviceConfig.name}).length -gt 0) {
			$Attempt = $Attempt + 1
			if ($Attempt -gt $MaximumAttempts){
				throw "Timeout while waiting for service '$($serviceConfig.name)' to be deleted"
			}
			Write-Host "Waiting for service '$($serviceConfig.name)' to be deleted"
			Sleep 1
		}

		# uninstall any custom .net installers that may be in the host assembly		
		$hostAssemblyName = $serviceConfig.name +  ".dll"
		$hostAssemblyFilePath = (Join-Path $rootPath $hostAssemblyName).ToString()
		
		if(Test-Path $hostAssemblyFilePath)
		{
			Uninstall-Util $hostAssemblyFilePath
		} else	{
			Write-Log "Can not find assembly $hostAssemblyFilePath so not running uninstall-util"
		}
	}
}

function Uninstall-NServiceBus {
	param(
		[Parameter(Mandatory = $true)]
		[string]
		$rootPath,	   
        [Parameter(Mandatory = $true)]
		[System.XML.XMLElement]
		$serviceConfig
	)

	$service = GetService $serviceConfig.name
	if ($service)
	{
		Stop-WindowsService -serviceConfig $serviceConfig

		$profiles = @($serviceConfig.profiles.profile) -join " "

		& $rootPath\NServiceBus.Host.exe $profiles /uninstall /serviceName:$($serviceConfig.name)
		if($LASTEXITCODE -ne 0) {
			throw "NServiceBus.Host.exe raised an error, please review log messages"
		}

		# uninstall any custom .net installers that may be in the host assembly		
		$hostAssemblyName = $serviceConfig.name +  ".dll"
		$hostAssemblyFilePath = (Join-Path $rootPath $hostAssemblyName).ToString()
		
		if(Test-Path $hostAssemblyFilePath)
		{
			Uninstall-Util $hostAssemblyFilePath
		} else	{
			Write-Log "Can not find assembly $hostAssemblyFilePath so not running uninstall-util"
		}
	}
}

function Uninstall-TopshelfService {
	param(
		[Parameter(Mandatory = $true)]
		[string]
		$rootPath,	   
        [Parameter(Mandatory = $true)]
		[System.XML.XMLElement]
		$serviceConfig
	)

	$service = GetService $serviceConfig.name
	if ($service)
	{
		Stop-WindowsService -serviceConfig $serviceConfig

		# Don't want to force a reboot every uninstall
		$removeService = "sc.exe delete $($serviceConfig.name)"
		Invoke-Expression -Command $removeService -ErrorAction Stop

		$MaximumAttempts = 10
		$Attempt = 0
		while ((get-service | ?{$_.Name -eq $serviceConfig.name}).length -gt 0) {
			$Attempt = $Attempt + 1
			if ($Attempt -gt $MaximumAttempts){
				throw "Timeout while waiting for service '$($serviceConfig.name)' to be deleted"
			}
			Write-Host "Waiting for service '$($serviceConfig.name)' to be deleted"
			Sleep 1
		}

		# uninstall service	

		$arguments = @()
		$arguments += "uninstall"
		$arguments += "-servicename `"$($serviceConfig.Name)`""

		$binPath = $serviceConfig.path

		if($binPath.StartsWith(".")) {
			$binPath = (Join-Path $rootPath $binPath.SubString(1, $binPath.Length - 1)).ToString()
		}

		$servicePath = $binPath

		Start-Process $servicePath -Argument $arguments -Wait

		# uninstall any custom .net installers that may be in the host assembly		
		$hostAssemblyName = $serviceConfig.name +  ".dll"
		$hostAssemblyFilePath = (Join-Path $rootPath $hostAssemblyName).ToString()
		
		if(Test-Path $hostAssemblyFilePath)
		{
			Uninstall-Util $hostAssemblyFilePath
		} else	{
			Write-Log "Can not find assembly $hostAssemblyFilePath so not running uninstall-util"
		}
	}
}

function Stop-WindowsService {
	param(	   
        [Parameter(Mandatory = $true)]
		[System.XML.XMLElement]
		$serviceConfig
	)

	$service = GetService $serviceConfig.name
	if($service) {
		Stop-Service $serviceConfig.name
	} else {
		Write-Log "Could not find $($serviceConfig.name) installed on the system"
	}
}

function Start-WindowsService {
	param(   
        [Parameter(Mandatory = $true)]
		[System.XML.XMLElement]
		$serviceConfig
	)

	$service = GetService $serviceConfig.name
	if($service) {
		Start-Service $serviceConfig.name
	} else {
		Write-Log "Could not find $($serviceConfig.name) installed on the system"
	}
}

function Get-MetadataForWindowsService {
    param(   
        [Parameter(Mandatory = $true)]
        [System.XML.XMLElement]
        $serviceConfig
    )

	$binPath = $serviceConfig.path

	if($binPath.StartsWith(".")) {
		$binPath = (Join-Path $rootPath $binPath.SubString(1, $binPath.Length - 1)).ToString()
	}

	$serviceContainer = $serviceConfig.serviceContainer

	$servicePath = $binPath

	$metaData = @()
    $metaData += Get-MetaDataFromAssembly -assemblyFilePath $servicePath 
    return $metaData
}


function Get-MetadataForNServiceBus {
    param(   
        [Parameter(Mandatory = $true)]
        [System.XML.XMLElement]
        $serviceConfig
    )

	$binPath = $serviceConfig.path

	if($binPath.StartsWith(".")) {
		$binPath = (Join-Path $rootPath $binPath.SubString(1, $binPath.Length - 1)).ToString()
	}

	$servicePath = $binPath

	$metaData = @()
    $metaData += Get-MetaDataFromAssembly -assemblyFilePath $servicePath 
	return $metaData
}


function Get-MetadataForTopshelfService {
    param(   
        [Parameter(Mandatory = $true)]
        [System.XML.XMLElement]
        $serviceConfig
    )

	$binPath = $serviceConfig.path

	if($binPath.StartsWith(".")) {
		$binPath = (Join-Path $rootPath $binPath.SubString(1, $binPath.Length - 1)).ToString()
	}

	$servicePath = $binPath

	$metaData = @()
    $metaData += Get-MetaDataFromAssembly -assemblyFilePath $servicePath 
    return $metaData
}

function Get-MetadataForJavaService {
    param(   
        [Parameter(Mandatory = $true)]
        [System.XML.XMLElement]
        $serviceConfig
    )

	$metaData = @()    
    return $metaData
}

function GetService {
    param(   
        [Parameter(Mandatory = $true)]
        [string]
        $serviceName
    )

    $serviceObj =(Get-WmiObject Win32_Service -filter "name='$serviceName'")
    if($serviceObj -eq $null) {
    	return $null
    }

    return Get-Service -name $serviceName
}