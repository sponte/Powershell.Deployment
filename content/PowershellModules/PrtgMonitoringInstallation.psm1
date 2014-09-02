function Install-PrtgMonitors {
 param(  
        [Parameter(Mandatory = $true)]
        [string]
        $rootPath,
        [Parameter(Mandatory = $true)]
        [System.XML.XMLDocument]
        $configuration
    )
	
    foreach($prtgMonitorConfig in @($configuration.configuration.prtgMonitors.prtgMonitor)) {
        if(!$prtgMonitorConfig) { continue }
		
        Install-PrtgMonitor -rootPath $rootPath -prtgMonitorConfig $prtgMonitorConfig
    }
}

function Uninstall-PrtgMonitors {
 param(        
        [Parameter(Mandatory = $true)]
        [string]
        $rootPath,     
        [Parameter(Mandatory = $true)]
        [System.XML.XMLDocument]
        $configuration
    )
    
    foreach($prtgMonitorConfig in @($configuration.configuration.prtgMonitors.prtgMonitor)) {
        if(!$prtgMonitorConfig) { continue }
        Remove-PrtgMonitor -rootPath $rootPath -prtgMonitorConfig $prtgMonitorConfig
    }
}


function Stop-PrtgMonitors {
 param(        
        [Parameter(Mandatory = $true)]
        [string]
        $rootPath,     
        [Parameter(Mandatory = $true)]
        [System.XML.XMLDocument]
        $configuration
    )
    
    foreach($prtgMonitorConfig in @($configuration.configuration.prtgMonitors.prtgMonitor)) {
        if(!$prtgMonitorConfig) { continue }
        Stop-PrtgMonitor -rootPath $rootPath -prtgMonitorConfig $prtgMonitorConfig
    }
}

function Start-PrtgMonitors {
 param(        
        [Parameter(Mandatory = $true)]
        [string]
        $rootPath,     
        [Parameter(Mandatory = $true)]
        [System.XML.XMLDocument]
        $configuration
    )
    
    foreach($prtgMonitorConfig in @($configuration.configuration.prtgMonitors.prtgMonitor)) {
        if(!$prtgMonitorConfig) { continue }
        Start-PrtgMonitor -rootPath $rootPath -prtgMonitorConfig $prtgMonitorConfig
    }
}



# Group Methods

function Install-PrtgMonitor {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $rootPath,     
        [Parameter(Mandatory = $true)]
        [System.XML.XMLElement]
        $prtgMonitorConfig
    )

    foreach($sensorConfig in @($prtgMonitorConfig.sensors.sensor)) {
        if(!$sensorConfig) { continue }
        Install-PrtgSensor $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -sensorConfig $sensorConfig
    }
}


function Remove-PrtgMonitor {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $rootPath,     
        [Parameter(Mandatory = $true)]
        [System.XML.XMLElement]
        $prtgMonitorConfig
    )

    foreach($sensorConfig in @($prtgMonitorConfig.sensors.sensor)) {
        if(!$sensorConfig) { continue }
        Remove-PrtgSensor $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -sensorConfig $sensorConfig
    }
}



function Stop-PrtgMonitor {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $rootPath,     
        [Parameter(Mandatory = $true)]
        [System.XML.XMLElement]
        $prtgMonitorConfig
    )

    foreach($sensorConfig in @($prtgMonitorConfig.sensors.sensor)) {
        if(!$sensorConfig) { continue }
        Stop-PrtgSensor $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -sensorConfig $sensorConfig
    }
}

function Start-PrtgMonitor {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $rootPath,     
        [Parameter(Mandatory = $true)]
        [System.XML.XMLElement]
        $prtgMonitorConfig
    )

    foreach($sensorConfig in @($prtgMonitorConfig.sensors.sensor)) {
        if(!$sensorConfig) { continue }
        Start-PrtgSensor $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -sensorConfig $sensorConfig
    }
}

# Methods for single items


function Install-PrtgSensor {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $rootPath,     
        [Parameter(Mandatory = $true)]
        [System.XML.XMLElement]
        $sensorConfig,
		[Parameter(Mandatory = $true)]
        [string]
        $apiUrl,     
		[Parameter(Mandatory = $true)]
        [string]
        $login,     
		[Parameter(Mandatory = $true)]
        [string]
        $passwordHash 

    )

	$apiPath = Join-Path $rootPath "deployment\PowershellModules\Tools\PrtgSetupTool.exe"
	$baseSensorId = $sensorConfig.baseSensorId
	$sensorDeviceId = $sensorConfig.sensorDeviceId
	$sensorName = $sensorConfig.sensorName
	$sensorUrl = $sensorConfig.sensorUrl
	
	Write-Log "Install Sensor  -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -s $sensorUrl -a Exist"
	&$apiPath -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -s $sensorUrl -a Install

}


function Remove-PrtgSensor {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $rootPath,     
        [Parameter(Mandatory = $true)]
        [System.XML.XMLElement]
        $sensorConfig,
		[Parameter(Mandatory = $true)]
        [string]
        $apiUrl,     
		[Parameter(Mandatory = $true)]
        [string]
        $login,     
		[Parameter(Mandatory = $true)]
        [string]
        $passwordHash 
    )

    if($sensorConfig.deleteOnUninstall)
	{
		$apiPath = Join-Path $rootPath "deployment\PowershellModules\Tools\PrtgSetupTool.exe"
	    $baseSensorId = $sensorConfig.baseSensorId
	    $sensorDeviceId = $sensorConfig.sensorDeviceId
	    $sensorName = $sensorConfig.sensorName
	    $sensorUrl = $sensorConfig.sensorUrl
	
		Write-Log "Delete Sensor  -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -s $sensorUrl -a Exist"
	    &$apiPath -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -s $sensorUrl -a delete
	}
    else	
    {
        host-write "Removal of sensor not allowed"
    }

}

function Stop-PrtgSensor {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $rootPath,     
        [Parameter(Mandatory = $true)]
        [System.XML.XMLElement]
        $sensorConfig,
		[Parameter(Mandatory = $true)]
        [string]
        $apiUrl,     
		[Parameter(Mandatory = $true)]
        [string]
        $login,     
		[Parameter(Mandatory = $true)]
        [string]
        $passwordHash 
    )

	$apiPath = Join-Path $rootPath "deployment\PowershellModules\Tools\PrtgSetupTool.exe"
	$baseSensorId = $sensorConfig.baseSensorId
	$sensorDeviceId = $sensorConfig.sensorDeviceId
	$sensorName = $sensorConfig.sensorName
	$sensorUrl = $sensorConfig.sensorUrl
	
	Write-Log "Pause Sensor  -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -s $sensorUrl -a Exist"
	&$apiPath -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -s $sensorUrl -a pause

}


function Start-PrtgSensor {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $rootPath,     
        [Parameter(Mandatory = $true)]
        [System.XML.XMLElement]
        $sensorConfig,
		[Parameter(Mandatory = $true)]
        [string]
        $apiUrl,     
		[Parameter(Mandatory = $true)]
        [string]
        $login,     
		[Parameter(Mandatory = $true)]
        [string]
        $passwordHash 
    )

	$apiPath = Join-Path $rootPath "deployment\PowershellModules\Tools\PrtgSetupTool.exe"
	$baseSensorId = $sensorConfig.baseSensorId
	$sensorDeviceId = $sensorConfig.sensorDeviceId
	$sensorName = $sensorConfig.sensorName
	$sensorUrl = $sensorConfig.sensorUrl
	
	Write-Log "Resume Sensor  -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -s $sensorUrl -a Exist"
	&$apiPath -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -s $sensorUrl -a resume

}

function Test-PrtgSensor {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $rootPath,     
        [Parameter(Mandatory = $true)]
        [System.XML.XMLElement]
        $sensorConfig,
		[Parameter(Mandatory = $true)]
        [string]
        $apiUrl,     
		[Parameter(Mandatory = $true)]
        [string]
        $login,     
		[Parameter(Mandatory = $true)]
        [string]
        $passwordHash 
    )

	$apiPath = Join-Path $rootPath "deployment\PowershellModules\Tools\PrtgSetupTool.exe"
	$baseSensorId = $sensorConfig.baseSensorId
	$sensorDeviceId = $sensorConfig.sensorDeviceId
	$sensorName = $sensorConfig.sensorName
	$sensorUrl = $sensorConfig.sensorUrl
	
	Write-Log "Checking Sensor  -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -s $sensorUrl -a Exist"
	$exists = &$apiPath -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -s $sensorUrl -a Exist
	return $exists -eq "true"

}