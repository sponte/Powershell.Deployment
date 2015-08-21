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

    foreach($sensorConfig in @($prtgMonitorConfig.serviceBusSubscribeSensors.serviceBusSubscribeSensor)) {
        if(!$sensorConfig) { continue }
        Install-PrtgServiceBusSubscribeSensors $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -sensorConfig $sensorConfig
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
		if(Test-PrtgSensor $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -sensorConfig $sensorConfig) 
		{ 
        Remove-PrtgSensor $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -sensorConfig $sensorConfig
        }
        
    }
    foreach($sensorConfig in @($prtgMonitorConfig.serviceBusSubscribeSensors.serviceBusSubscribeSensor)) {
        if(!$sensorConfig) { continue }
		if(Test-PrtgServiceBusSubscribeSensors $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -sensorConfig $sensorConfig) 
		{ 
        Remove-PrtgServiceBusSubscribeSensors $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -sensorConfig $sensorConfig
        }
        
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
        if(Test-PrtgSensor $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -sensorConfig $sensorConfig) 
		{ 
        Stop-PrtgSensor $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -sensorConfig $sensorConfig
    }
    }

    foreach($sensorConfig in @($prtgMonitorConfig.serviceBusSubscribeSensors.serviceBusSubscribeSensor)) {
        if(!$sensorConfig) { continue }
        if(Test-PrtgServiceBusSubscribeSensors $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -sensorConfig $sensorConfig) 
		{ 
        Write-Output "Stop PrtgServiceBusSubscribeSensors"
        Stop-PrtgServiceBusSubscribeSensors $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -sensorConfig $sensorConfig
        }
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
        if(Test-PrtgSensor $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -sensorConfig $sensorConfig) 
		{             
            Start-PrtgSensor $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -sensorConfig $sensorConfig
        }
    }
    foreach($sensorConfig in @($prtgMonitorConfig.serviceBusSubscribeSensors.serviceBusSubscribeSensor)) {
        if(!$sensorConfig) { continue }
        if(Test-PrtgServiceBusSubscribeSensors $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -sensorConfig $sensorConfig) 
		{ 
        Write-Output "Start PrtgServiceBusSubscribeSensors"
        Start-PrtgServiceBusSubscribeSensors $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -sensorConfig $sensorConfig
        }
}
}

# Methods for single items PrtgSensor


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
	$sensorTimeout = $sensorConfig.sensorTimeout
	
	Write-Log "Install Sensor  -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -p $sensorUrl -t $sensorTimeout  -a Install"
	&$apiPath -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -p  $sensorUrl  -t $sensorTimeout -a Install

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

    if($sensorConfig.deleteOnUninstall -eq $true -or $sensorConfig.deleteOnUninstall -eq 1 )
	{
		$apiPath = Join-Path $rootPath "deployment\PowershellModules\Tools\PrtgSetupTool.exe"
	    $baseSensorId = $sensorConfig.baseSensorId
	    $sensorDeviceId = $sensorConfig.sensorDeviceId
	    $sensorName = $sensorConfig.sensorName
	    $sensorUrl = $sensorConfig.sensorUrl
	
		Write-Log "Delete Sensor  -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -p $sensorUrl -a delete"
	    &$apiPath -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -p $sensorUrl -a delete
	}
    else	
    {
        Write-Log "Removal of sensor not allowed"
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
	
	Write-Log "Pause Sensor  -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -p $sensorUrl -r:`"Pause for deployment`"  -a pause"
	&$apiPath -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -p $sensorUrl -r:`"Pause for deployment`"  -a pause

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
	
	Write-Log "Resume Sensor  -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -p $sensorUrl -a resume"
	&$apiPath -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -p $sensorUrl -a resume

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
	
	Write-Log "Checking Sensor  -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -p $sensorUrl -a Exist"
	$exists = &$apiPath -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -p $sensorUrl -a Exist
	return $exists -eq "true"

}


# Methods for single items PrtgServiceBusSubscribeSensors


function Install-PrtgServiceBusSubscribeSensors {
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
    $sensorParameter = "-connectionString  '$($sensorConfig.connectionString)' -topic '$($sensorConfig.subscriptionTopic)' -subscriptionName '$($sensorConfig.subscriptionName)'"

    
    Write-Log "Install PrtgServiceBusSubscribeSensors  -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -p:`"$sensorParameter`" -a Install"
	#&$apiPath -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -p:`"$($sensorParameter)`" -a Install
    $tmp = "`"`"$apiPath`" -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -p:`"$($sensorParameter)`" -a Install`""	
    #Workaround for powershel not being able to escape quotes in commands
    cmd /c $tmp         

    
}


function Remove-PrtgServiceBusSubscribeSensors {
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

    if($sensorConfig.deleteOnUninstall -eq $true -or $sensorConfig.deleteOnUninstall -eq 1 )
	{
		$apiPath = Join-Path $rootPath "deployment\PowershellModules\Tools\PrtgSetupTool.exe"
	    $baseSensorId = $sensorConfig.baseSensorId
	    $sensorDeviceId = $sensorConfig.sensorDeviceId
	    $sensorName = $sensorConfig.sensorName
	    $sensorParameter = "-connectionString  '$($sensorConfig.connectionString)' -topic '$($sensorConfig.subscriptionTopic)' -subscriptionName '$($sensorConfig.subscriptionName)'"
	
        Write-Log "Delete PrtgServiceBusSubscribeSensors  -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -p:`"$sensorParameter`" -a delete"
	    #&$apiPath -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -p:`"$($sensorParameter)`" -a Install
        $tmp = "`"`"$apiPath`" -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -p:`"$($sensorParameter)`" -a delete`""
        #Workaround for powershel not being able to escape quotes in commands
        cmd /c $tmp    		
	}
    else	
    {
        Write-Log "Removal of sensor not allowed"
    }

}

function Stop-PrtgServiceBusSubscribeSensors {
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
	$sensorParameter = "-connectionString  '$($sensorConfig.connectionString)' -topic '$($sensorConfig.subscriptionTopic)' -subscriptionName '$($sensorConfig.subscriptionName)'"
	
    Write-Log "Pause PrtgServiceBusSubscribeSensors  -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -p:`"$sensorParameter`" -r:`"Pause for deployment`" -a pause"

	#&$apiPath -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -p:`"$($sensorParameter)`" -a Install
    $tmp = "`"`"$apiPath`" -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -p:`"$($sensorParameter)`" -r:`"Pause for deployment`" -a pause`""
    #Workaround for powershel not being able to escape quotes in commands	
    cmd /c $tmp  		

}


function Start-PrtgServiceBusSubscribeSensors {
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
	$sensorParameter = "-connectionString  '$($sensorConfig.connectionString)' -topic '$($sensorConfig.subscriptionTopic)' -subscriptionName '$($sensorConfig.subscriptionName)'"
	
    Write-Log "Resume PrtgServiceBusSubscribeSensors  -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -p:`"$sensorParameter`" -a resume"
	#&$apiPath -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -p:`"$($sensorParameter)`" -a Install
    $tmp = "`"`"$apiPath`" -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -p:`"$($sensorParameter)`" -a resume`""
    #Workaround for powershel not being able to escape quotes in commands
    cmd /c $tmp  			
}

function Test-PrtgServiceBusSubscribeSensors {
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
	$sensorParameter = "-connectionString  '$($sensorConfig.connectionString)' -topic '$($sensorConfig.subscriptionTopic)' -subscriptionName '$($sensorConfig.subscriptionName)'"
	
    Write-Log "Checking PrtgServiceBusSubscribeSensors  -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -p:`"$sensorParameter`" -a Exist"
	#&$apiPath -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -p:`"$($sensorParameter)`" -a Install
    $tmp = "`"`"$apiPath`" -b $baseSensorId -l $login -h $passwordHash -u $apiUrl -d $sensorDeviceId -n $sensorName -p:`"$($sensorParameter)`" -a Exist`""
    #Workaround for powershel not being able to escape quotes in commands
    $exist = &cmd /c $tmp  		
    Write-Log "Exists returned $exist"         
    return [System.Convert]::ToBoolean($exist) 
    
}


