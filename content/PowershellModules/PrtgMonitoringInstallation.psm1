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
        
        Install-PrtgMonitor -rootPath $rootPath -prtgMonitorConfig $prtgMonitorConfig -serviceBusConfig $configuration.configuration.serviceBuses
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
        Remove-PrtgMonitor -rootPath $rootPath -prtgMonitorConfig $prtgMonitorConfig -serviceBusConfig $configuration.configuration.serviceBuses
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
        Stop-PrtgMonitor -rootPath $rootPath -prtgMonitorConfig $prtgMonitorConfig -serviceBusConfig $configuration.configuration.serviceBuses
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
        Start-PrtgMonitor -rootPath $rootPath -prtgMonitorConfig $prtgMonitorConfig -serviceBusConfig $configuration.configuration.serviceBuses
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
        $prtgMonitorConfig,
        [Parameter(Mandatory = $false)]
        [System.XML.XMLElement]
        $serviceBusConfig
    )

    foreach($sensorConfig in @($prtgMonitorConfig.sensors.sensor)) {
        if(!$sensorConfig) { continue }
        Install-PrtgSensor $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -sensorConfig $sensorConfig
    }

    if ($serviceBusConfig) {
        if ($prtgMonitorConfig.serviceBusSubscribeSensors.conventionServiceBusSubscribeSensor) {
            $conventionServiceBusSubscribeSensorConfig = $prtgMonitorConfig.serviceBusSubscribeSensors.conventionServiceBusSubscribeSensor

            foreach($serviceBusTopicConfig in @($serviceBusConfig.serviceBus.topics.topic)) {
                if(!$serviceBusTopicConfig) { continue }

                foreach($serviceBusTopicSubscriptionConfig in @($serviceBusTopicConfig.subscriptions.subscription)) {
                    if(!$serviceBusTopicSubscriptionConfig) { continue }

                    $deleteOnUninstall = $conventionServiceBusSubscribeSensorConfig.deleteOnUninstall
                    $sensorTimeout = $conventionServiceBusSubscribeSensorConfig.sensorTimeout
                    $connectionString = $conventionServiceBusSubscribeSensorConfig.connectionString
                    $templateGroupName = $conventionServiceBusSubscribeSensorConfig.templateGroupName
                    $templateDeviceName = $conventionServiceBusSubscribeSensorConfig.templateDeviceName
                    $templateSensorName = $conventionServiceBusSubscribeSensorConfig.templateSensorName

                    $subscriptionTopic = $serviceBusTopicConfig.name
                    $subscriptionName = $serviceBusTopicSubscriptionConfig.name
                    $groupName = $conventionServiceBusSubscribeSensorConfig.groupName
                    $deviceName = $conventionServiceBusSubscribeSensorConfig.deviceName
                    $sensorName = "$($subscriptionTopic)-$($subscriptionName)"
                    $sensorParameter = "-connectionString  '$($connectionString)' -topic '$($subscriptionTopic)' -subscriptionName '$($subscriptionName)'"
                
                    Install-PrtgConventionServiceBusSubscribeSensors $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName -deleteOnUninstall $deleteOnUninstall -sensorTimeout $sensorTimeout -templateGroupName $templateGroupName -templateDeviceName $templateDeviceName -templateSensorName $templateSensorName -sensorParameter $sensorParameter
                }
            }            
        }
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
        $prtgMonitorConfig,
        [Parameter(Mandatory = $false)]
        [System.XML.XMLElement]
        $serviceBusConfig
    )

    foreach($sensorConfig in @($prtgMonitorConfig.sensors.sensor)) {
        if(!$sensorConfig) { continue }
        if(Test-PrtgSensor $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -sensorConfig $sensorConfig) 
        { 
            Remove-PrtgSensor $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -sensorConfig $sensorConfig
        }
    }

    if ($serviceBusConfig) {
        if ($prtgMonitorConfig.serviceBusSubscribeSensors.conventionServiceBusSubscribeSensor) {
            $conventionServiceBusSubscribeSensorConfig = $prtgMonitorConfig.serviceBusSubscribeSensors.conventionServiceBusSubscribeSensor

            foreach($serviceBusTopicConfig in @($serviceBusConfig.serviceBus.topics.topic)) {
                if(!$serviceBusTopicConfig) { continue }

                foreach($serviceBusTopicSubscriptionConfig in @($serviceBusTopicConfig.subscriptions.subscription)) {
                    if(!$serviceBusTopicSubscriptionConfig) { continue }

                    $deleteOnUninstall = $conventionServiceBusSubscribeSensorConfig.deleteOnUninstall
                    $subscriptionTopic = $serviceBusTopicConfig.name
                    $subscriptionName = $serviceBusTopicSubscriptionConfig.name
                    $groupName = $conventionServiceBusSubscribeSensorConfig.groupName
                    $deviceName = $conventionServiceBusSubscribeSensorConfig.deviceName
                    $sensorName = "$($subscriptionTopic)-$($subscriptionName)"
                
                    if(Test-PrtgConventionServiceBusSubscribeSensors $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName) 
                    { 
                        Write-Output "Remove PrtgConventionServiceBusSubscribeSensor"
                        Remove-PrtgConventionServiceBusSubscribeSensors $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName -deleteOnUninstall $deleteOnUninstall
                    }
                }
            }            
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
        $prtgMonitorConfig,
        [Parameter(Mandatory = $false)]
        [System.XML.XMLElement]
        $serviceBusConfig
    )

    foreach($sensorConfig in @($prtgMonitorConfig.sensors.sensor)) {
        if(!$sensorConfig) { continue }
        if(Test-PrtgSensor $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -sensorConfig $sensorConfig) 
        { 
            Stop-PrtgSensor $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -sensorConfig $sensorConfig
        }
    }

    if ($serviceBusConfig) {
        if ($prtgMonitorConfig.serviceBusSubscribeSensors.conventionServiceBusSubscribeSensor) {
            $conventionServiceBusSubscribeSensorConfig = $prtgMonitorConfig.serviceBusSubscribeSensors.conventionServiceBusSubscribeSensor

            foreach($serviceBusTopicConfig in @($serviceBusConfig.serviceBus.topics.topic)) {
                if(!$serviceBusTopicConfig) { continue }

                foreach($serviceBusTopicSubscriptionConfig in @($serviceBusTopicConfig.subscriptions.subscription)) {
                    if(!$serviceBusTopicSubscriptionConfig) { continue }

                    $subscriptionTopic = $serviceBusTopicConfig.name
                    $subscriptionName = $serviceBusTopicSubscriptionConfig.name
                    $groupName = $conventionServiceBusSubscribeSensorConfig.groupName
                    $deviceName = $conventionServiceBusSubscribeSensorConfig.deviceName
                    $sensorName = "$($subscriptionTopic)-$($subscriptionName)"
                
                    if(Test-PrtgConventionServiceBusSubscribeSensors $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName) 
                    { 
                        Write-Output "Stop PrtgConventionServiceBusSubscribeSensor"
                        Stop-PrtgConventionServiceBusSubscribeSensors $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName
                    }
                }
            }            
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
        $prtgMonitorConfig,
        [Parameter(Mandatory = $false)]
        [System.XML.XMLElement]
        $serviceBusConfig
    )

    foreach($sensorConfig in @($prtgMonitorConfig.sensors.sensor)) {
        if(!$sensorConfig) { continue }
        if(Test-PrtgSensor $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -sensorConfig $sensorConfig) 
        {             
            Start-PrtgSensor $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -sensorConfig $sensorConfig
        }
    }

    if ($serviceBusConfig) {
        if ($prtgMonitorConfig.serviceBusSubscribeSensors.conventionServiceBusSubscribeSensor) {
            $conventionServiceBusSubscribeSensorConfig = $prtgMonitorConfig.serviceBusSubscribeSensors.conventionServiceBusSubscribeSensor

            foreach($serviceBusTopicConfig in @($serviceBusConfig.serviceBus.topics.topic)) {
                if(!$serviceBusTopicConfig) { continue }

                foreach($serviceBusTopicSubscriptionConfig in @($serviceBusTopicConfig.subscriptions.subscription)) {
                    if(!$serviceBusTopicSubscriptionConfig) { continue }

                    $subscriptionTopic = $serviceBusTopicConfig.name
                    $subscriptionName = $serviceBusTopicSubscriptionConfig.name
                    $groupName = $conventionServiceBusSubscribeSensorConfig.groupName
                    $deviceName = $conventionServiceBusSubscribeSensorConfig.deviceName
                    $sensorName = "$($subscriptionTopic)-$($subscriptionName)"
                
                    if(Test-PrtgConventionServiceBusSubscribeSensors $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName) 
                    { 
                        Write-Output "Start PrtgConventionServiceBusSubscribeSensor"
                        Start-PrtgConventionServiceBusSubscribeSensors $rootPath -apiUrl $prtgMonitorConfig.url -login $prtgMonitorConfig.login -passwordHash $prtgMonitorConfig.passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName
                    }
                }
            }            
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

    $templateGroupName = $sensorConfig.templateGroupName
    $templateDeviceName = $sensorConfig.templateDeviceName
    $templateSensorName = $sensorConfig.templateSensorName

    $groupName = $sensorConfig.groupName
    $deviceName = $sensorConfig.deviceName
    $sensorName = $sensorConfig.sensorName

    $sensorTimeout = $sensorConfig.sensorTimeout
    $sensorParameter = "$($sensorConfig.sensorUrl)"

    Write-Log "Getting sensor id for PrtgSensor for $groupName/$deviceName/$sensorName"
    $sensorIds = Get-PrtgSensors -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName

    if (!$sensorIds){
        Write-Log "Getting PrtgSensor group id for $groupName"
        $groupId = Get-PrtgGroup -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName
        if (!$groupId){
            throw "Unable to get group id for $groupName"
        }
        Write-Log "PrtgSensor group id is $groupId"

        Write-Log "Getting PrtgSensor device id for $groupName/$deviceName"
        $deviceId = Get-PrtgDevice -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName
        if (!$deviceId){
            Write-Log "Device does not exist so copy it from template"

            Write-Log "Getting PrtgSensor template device id for $templateGroupName/$templateDeviceName"
            $templateDeviceId = Get-PrtgDevice -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $templateGroupName -deviceName $templateDeviceName
            if (!$templateDeviceId){
                throw "Unable to get template device id for $templateGroupName/$templateDeviceName"
            }
            Write-Log "PrtgSensor template device id is $templateDeviceId"

            Write-Log "Copying PrtgSensor device from $templateGroupName/$templateDeviceName to $groupName/$deviceName"
            $deviceId = Copy-PrtgDevice -apiUrl $apiUrl -login $login -passwordHash $passwordHash -templateDeviceId $templateDeviceId -groupId $groupId -deviceName $deviceName
            if (!$deviceId){
                throw "Unable to copy device from $templateGroupName/$templateDeviceName to $groupName/$deviceName "
            }
        }
        Write-Log "PrtgSensor device id is $deviceId"


        Write-Log "Getting PrtgSensor template sensor id for $templateGroupName/$templateDeviceName/$templateSensorName"
        $templateSensorId = Get-PrtgSensor -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $templateGroupName -deviceName $templateDeviceName -sensorName $templateSensorName
        if (!$templateSensorId){
            throw "Unable to get template sensor id for $templateGroupName/$templateDeviceName/$templateSensorName"
        }
        Write-Log "PrtgSensor template sensor id is $templateSensorId"

        Write-Log "Copying PrtgSensor sensor from $templateGroupName/$templateDeviceName/$templateSensorName to $groupName/$deviceName/$sensorName"
        $sensorId = Copy-PrtgSensor -apiUrl $apiUrl -login $login -passwordHash $passwordHash -templateSensorId $templateSensorId -deviceId $deviceId -sensorName $sensorName
        if (!$sensorId){
            throw "Unable to copy sensor from $templateGroupName/$templateDeviceName/$templateSensorName to $groupName/$deviceName/$sensorName "
        }
 
        Write-Log "PrtgSensor sensor id is $sensorId"
       
        Write-Log "Setting PrtgSensor sensor property $groupName/$deviceName/$sensorName/exeparams to $sensorParameter"
        $result = Set-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "exeparams" -propertyValue $sensorParameter
        if (!$result){
            throw "Unable to set prtg sensor property $groupName/$deviceName/$sensorName/exeparams set to $sensorParameter"
        } 
        Write-Log "PrtgSensor sensor property $groupName/$deviceName/$sensorName/exeparams set to $sensorParameter"

        if ($sensorTimeout -ne 0){
            Write-Log "Setting PrtgSensor sensor property $groupName/$deviceName/$sensorName/timeout to $sensorParameter"
            $result = Set-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "timeout" -propertyValue $sensorTimeout
            if (!$result){
                throw "Unable to set prtg sensor property $groupName/$deviceName/$sensorName/timeout set to $sensorTimeout"
            } 
            Write-Log "PrtgSensor sensor property $groupName/$deviceName/$sensorName/timeout set to $sensorTimeout"
        }

        $sensorIds=@()
        do
        {
            Write-Log "Check for duplicate sensor id for PrtgSensor for $groupName/$deviceName/$sensorName"
            $sensorIds = Get-PrtgSensors -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName

            if ($sensorIds.Count -gt 1){
                $sensorIds | Sort-Object | select -skip 1 | %{
                    $sensorId = $_
                    Write-Log "Delete PrtgSensor for $sensorId"
                    Delete-PrtgObject -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId
                }
                Write-Log "Wait 5 seconds and then check again"
                start-sleep -seconds 5
            }
        } while ($sensorIds.Count -gt 1)    
    } else {
        $sensorIds | %{
            $sensorId = $_
            Write-Log "Getting PrtgSensor sensor property for $groupName/$deviceName/$sensorName/exeparams"
            $oldSensorParameter = Get-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "exeparams"

            if ($oldSensorParameter -ne $sensorParameter){
                Write-Log "Setting PrtgSensor sensor property $groupName/$deviceName/$sensorName/exeparams to $sensorParameter"
                $result = Set-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "exeparams" -propertyValue $sensorParameter
                if (!$result){
                    throw "Unable to set prtg sensor property $groupName/$deviceName/$sensorName/exeparams set to $sensorParameter"
                } 
                Write-Log "PrtgSensor sensor property $groupName/$deviceName/$sensorName/exeparams set to $sensorParameter"
            }

            if ($sensorTimeout -ne 0){
                Write-Log "Getting PrtgSensor sensor property for $groupName/$deviceName/$sensorName/timeout"
                $oldSensorTimeout = Get-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "timeout"

                if ($oldSensorTimeout -ne $sensorTimeout){
                    Write-Log "Setting PrtgSensor sensor property $groupName/$deviceName/$sensorName/exeparams to $sensorParameter"
                    $result = Set-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "timeout" -propertyValue $sensorTimeout
                    if (!$result){
                        throw "Unable to set prtg sensor property $groupName/$deviceName/$sensorName/timeout set to $sensorTimeout"
                    } 
                    Write-Log "PrtgSensor sensor property $groupName/$deviceName/$sensorName/timeout set to $sensorTimeout"
                }
            }
        }
    }
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
        $groupName = $sensorConfig.groupName
        $deviceName = $sensorConfig.deviceName
        $sensorName = $sensorConfig.sensorName

        Write-Log "Getting sensor ids for PrtgSensor for $groupName/$deviceName/$sensorName"
        $sensorIds = Get-PrtgSensors -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName

        $sensorIds | %{      
            $sensorId = $_
            Write-Log "Delete PrtgSensor for $sensorId"
            Delete-PrtgObject -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId
        }
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

    $groupName = $sensorConfig.groupName
    $deviceName = $sensorConfig.deviceName
    $sensorName = $sensorConfig.sensorName

    Write-Log "Getting sensor id for PrtgSensor for $groupName/$deviceName/$sensorName"
    $sensorIds = Get-PrtgSensors -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName

    $sensorIds | %{      
        $sensorId = $_
        Write-Log "Pause PrtgSensor for $sensorId"
        Stop-PrtgObject -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -message "Pause for deployment"
    }
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
    
    $groupName = $sensorConfig.groupName
    $deviceName = $sensorConfig.deviceName
    $sensorName = $sensorConfig.sensorName

    Write-Log "Getting sensor id for PrtgSensor for $groupName/$deviceName/$sensorName"
    $sensorIds = Get-PrtgSensors -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName

    $sensorIds | %{      
        $sensorId = $_
        Write-Log "Resume PrtgSensor for $sensorId"
        Start-PrtgObject -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId
    }
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

    $groupName = $sensorConfig.groupName
    $deviceName = $sensorConfig.deviceName
    $sensorName = $sensorConfig.sensorName

    Write-Log "Checking PrtgSensor for $groupName/$deviceName/$sensorName"
    $sensors = Get-PrtgSensors -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName

    return ($sensors -ne $null)
}

# Methods for single items PrtgServiceBusSubscribeSensors

function Install-PrtgConventionServiceBusSubscribeSensors {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $rootPath,     
        [Parameter(Mandatory = $true)]
        [string]
        $apiUrl,     
        [Parameter(Mandatory = $true)]
        [string]
        $login,     
        [Parameter(Mandatory = $true)]
        [string]
        $passwordHash,
        [Parameter(Mandatory = $true)]
        [string]
        $deleteOnUninstall, 
        [Parameter(Mandatory = $true)]
        [string]
        $sensorTimeout, 
        [Parameter(Mandatory = $true)]
        [string]
        $sensorParameter, 
        [Parameter(Mandatory = $true)]
        [string]
        $templateGroupName,   
        [Parameter(Mandatory = $true)]
        [string]
        $templateDeviceName,   
        [Parameter(Mandatory = $true)]
        [string]
        $templateSensorName,
        [Parameter(Mandatory = $true)]
        [string]
        $groupName, 
        [Parameter(Mandatory = $true)]
        [string]
        $deviceName, 
        [Parameter(Mandatory = $true)]
        [string]
        $sensorName
    )

    Write-Log "Getting sensor id for PrtgSensor for $groupName/$deviceName/$sensorName"
    $sensorIds = Get-PrtgSensors -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName

    if (!$sensorIds){
        Write-Log "Getting PrtgSensor group id for $groupName"
        $groupId = Get-PrtgGroup -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName
        if (!$groupId){
            throw "Unable to get group id for $groupName"
        }
        Write-Log "PrtgSensor group id is $groupId"

        Write-Log "Getting PrtgSensor device id for $groupName/$deviceName"
        $deviceId = Get-PrtgDevice -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName
        if (!$deviceId){
            Write-Log "Device does not exist so copy it from template"

            Write-Log "Getting PrtgSensor template device id for $templateGroupName/$templateDeviceName"
            $templateDeviceId = Get-PrtgDevice -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $templateGroupName -deviceName $templateDeviceName
            if (!$templateDeviceId){
                throw "Unable to get template device id for $templateGroupName/$templateDeviceName"
            }
            Write-Log "PrtgSensor template device id is $templateDeviceId"

            Write-Log "Copying PrtgSensor device from $templateGroupName/$templateDeviceName to $groupName/$deviceName"
            $deviceId = Copy-PrtgDevice -apiUrl $apiUrl -login $login -passwordHash $passwordHash -templateDeviceId $templateDeviceId -groupId $groupId -deviceName $deviceName
            if (!$deviceId){
                throw "Unable to copy device from $templateGroupName/$templateDeviceName to $groupName/$deviceName "
            }
        }
        Write-Log "PrtgSensor device id is $deviceId"


        Write-Log "Getting PrtgSensor template sensor id for $templateGroupName/$templateDeviceName/$templateSensorName"
        $templateSensorId = Get-PrtgSensor -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $templateGroupName -deviceName $templateDeviceName -sensorName $templateSensorName
        if (!$templateSensorId){
            throw "Unable to get template sensor id for $templateGroupName/$templateDeviceName/$templateSensorName"
        }
        Write-Log "PrtgSensor template sensor id is $templateSensorId"

        Write-Log "Copying PrtgSensor sensor from $templateGroupName/$templateDeviceName/$templateSensorName to $groupName/$deviceName/$sensorName"
        $sensorId = Copy-PrtgSensor -apiUrl $apiUrl -login $login -passwordHash $passwordHash -templateSensorId $templateSensorId -deviceId $deviceId -sensorName $sensorName
        if (!$sensorId){
            throw "Unable to copy sensor from $templateGroupName/$templateDeviceName/$templateSensorName to $groupName/$deviceName/$sensorName "
        }
 
        Write-Log "PrtgSensor sensor id is $sensorId"
       
        Write-Log "Setting PrtgSensor sensor property $groupName/$deviceName/$sensorName/exeparams to $sensorParameter"
        $result = Set-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "exeparams" -propertyValue $sensorParameter
        if (!$result){
            throw "Unable to set prtg sensor property $groupName/$deviceName/$sensorName/exeparams set to $sensorParameter"
        } 
        Write-Log "PrtgSensor sensor property $groupName/$deviceName/$sensorName/exeparams set to $sensorParameter"

        if ($sensorTimeout -ne 0){
            Write-Log "Setting PrtgSensor sensor property $groupName/$deviceName/$sensorName/timeout to $sensorParameter"
            $result = Set-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "timeout" -propertyValue $sensorTimeout
            if (!$result){
                throw "Unable to set prtg sensor property $groupName/$deviceName/$sensorName/timeout set to $sensorTimeout"
            } 
            Write-Log "PrtgSensor sensor property $groupName/$deviceName/$sensorName/timeout set to $sensorTimeout"
        }

        $sensorIds=@()
        do
        {
            Write-Log "Check for duplicate sensor id for PrtgSensor for $groupName/$deviceName/$sensorName"
            $sensorIds = Get-PrtgSensors -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName

            if ($sensorIds.Count -gt 1){
                $sensorIds | Sort-Object | select -skip 1 | %{
                    $sensorId = $_
                    Write-Log "Delete PrtgServiceBusSubscribeSensors for $sensorId"
                    Delete-PrtgObject -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId
                }
                Write-Log "Wait 5 seconds and then check again"
                start-sleep -seconds 5
            }
        } while ($sensorIds.Count -gt 1)          
    } else {
        $sensorIds | %{
            $sensorId = $_    
            Write-Log "Getting PrtgSensor sensor property for $groupName/$deviceName/$sensorName/exeparams"
            $oldSensorParameter = Get-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "exeparams"

            if ($oldSensorParameter -ne $sensorParameter){
                Write-Log "Setting PrtgSensor sensor property $groupName/$deviceName/$sensorName/exeparams to $sensorParameter"
                $result = Set-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "exeparams" -propertyValue $sensorParameter
                if (!$result){
                    throw "Unable to set prtg sensor property $groupName/$deviceName/$sensorName/exeparams set to $sensorParameter"
                } 
                Write-Log "PrtgSensor sensor property $groupName/$deviceName/$sensorName/exeparams set to $sensorParameter"
            }

            if ($sensorTimeout -ne 0){
                Write-Log "Getting PrtgSensor sensor property for $groupName/$deviceName/$sensorName/timeout"
                $oldSensorTimeout = Get-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "timeout"

                if ($oldSensorTimeout -ne $sensorTimeout){
                    Write-Log "Setting PrtgSensor sensor property $groupName/$deviceName/$sensorName/exeparams to $sensorParameter"
                    $result = Set-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "timeout" -propertyValue $sensorTimeout
                    if (!$result){
                        throw "Unable to set prtg sensor property $groupName/$deviceName/$sensorName/timeout set to $sensorTimeout"
                    } 
                    Write-Log "PrtgSensor sensor property $groupName/$deviceName/$sensorName/timeout set to $sensorTimeout"
                }
            }
        }
    }   
}

function Remove-PrtgConventionServiceBusSubscribeSensors {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $rootPath,     
        [Parameter(Mandatory = $true)]
        [string]
        $apiUrl,     
        [Parameter(Mandatory = $true)]
        [string]
        $login,     
        [Parameter(Mandatory = $true)]
        [string]
        $passwordHash,
        [Parameter(Mandatory = $true)]
        [string]
        $deleteOnUninstall, 
        [Parameter(Mandatory = $true)]
        [string]
        $groupName, 
        [Parameter(Mandatory = $true)]
        [string]
        $deviceName, 
        [Parameter(Mandatory = $true)]
        [string]
        $sensorName
    )

    if($deleteOnUninstall -eq $true -or $deleteOnUninstall -eq 1 )
    {
        $groupName = $sensorConfig.groupName
        $deviceName = $sensorConfig.deviceName
        $sensorName = $sensorConfig.sensorName

        Write-Log "Getting sensor id for PrtgServiceBusSubscribeSensors for $groupName/$deviceName/$sensorName"
        $sensorIds = Get-PrtgSensors -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName

        $sensorIds | %{      
            $sensorId = $_
            Write-Log "Delete PrtgServiceBusSubscribeSensors for $sensorId"
            Delete-PrtgObject -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId
        }
    }
    else    
    {
        Write-Log "Removal of sensor not allowed"
    }
}

function Stop-PrtgConventionServiceBusSubscribeSensors {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $rootPath,     
        [Parameter(Mandatory = $true)]
        [string]
        $apiUrl,     
        [Parameter(Mandatory = $true)]
        [string]
        $login,     
        [Parameter(Mandatory = $true)]
        [string]
        $passwordHash,
        [Parameter(Mandatory = $true)]
        [string]
        $groupName, 
        [Parameter(Mandatory = $true)]
        [string]
        $deviceName, 
        [Parameter(Mandatory = $true)]
        [string]
        $sensorName
    )

    Write-Log "Getting sensor id for PrtgServiceBusSubscribeSensor for $groupName/$deviceName/$sensorName"
    $sensorIds = Get-PrtgSensors -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName

    $sensorIds | %{      
        $sensorId = $_
        Write-Log "Pause PrtgServiceBusSubscribeSensor for $sensorId"
        Stop-PrtgObject -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -message "Pause for deployment"
    }
}

function Start-PrtgConventionServiceBusSubscribeSensors {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $rootPath,     
        [Parameter(Mandatory = $true)]
        [string]
        $apiUrl,     
        [Parameter(Mandatory = $true)]
        [string]
        $login,     
        [Parameter(Mandatory = $true)]
        [string]
        $passwordHash,
        [Parameter(Mandatory = $true)]
        [string]
        $groupName, 
        [Parameter(Mandatory = $true)]
        [string]
        $deviceName, 
        [Parameter(Mandatory = $true)]
        [string]
        $sensorName
    )

    Write-Log "Getting sensor id for PrtgServiceBusSubscribeSensor for $groupName/$deviceName/$sensorName"
    $sensorIds = Get-PrtgSensors -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName

    $sensorIds | %{      
        $sensorId = $_
        Write-Log "Resume PrtgServiceBusSubscribeSensor for $sensorId"
        Start-PrtgObject -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId
    }
}

function Test-PrtgConventionServiceBusSubscribeSensors {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $rootPath,     
        [Parameter(Mandatory = $true)]
        [string]
        $apiUrl,     
        [Parameter(Mandatory = $true)]
        [string]
        $login,     
        [Parameter(Mandatory = $true)]
        [string]
        $passwordHash, 
        [Parameter(Mandatory = $true)]
        [string]
        $groupName, 
        [Parameter(Mandatory = $true)]
        [string]
        $deviceName, 
        [Parameter(Mandatory = $true)]
        [string]
        $sensorName
    )

    Write-Log "Checking PrtgServiceBusSubscribeSensor for $groupName/$deviceName/$sensorName"
    $sensors = Get-PrtgSensors -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName

    return ($sensors -ne $null)
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

    $templateGroupName = $sensorConfig.templateGroupName
    $templateDeviceName = $sensorConfig.templateDeviceName
    $templateSensorName = $sensorConfig.templateSensorName

    $groupName = $sensorConfig.groupName
    $deviceName = $sensorConfig.deviceName
    $sensorName = $sensorConfig.sensorName

    $sensorTimeout = $sensorConfig.sensorTimeout
    $sensorParameter = "-connectionString  '$($sensorConfig.connectionString)' -topic '$($sensorConfig.subscriptionTopic)' -subscriptionName '$($sensorConfig.subscriptionName)'"

    Write-Log "Getting sensor id for PrtgSensor for $groupName/$deviceName/$sensorName"
    $sensorIds = Get-PrtgSensors -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName

    if (!$sensorIds){
        Write-Log "Getting PrtgSensor group id for $groupName"
        $groupId = Get-PrtgGroup -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName
        if (!$groupId){
            throw "Unable to get group id for $groupName"
        }
        Write-Log "PrtgSensor group id is $groupId"

        Write-Log "Getting PrtgSensor device id for $groupName/$deviceName"
        $deviceId = Get-PrtgDevice -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName
        if (!$deviceId){
            Write-Log "Device does not exist so copy it from template"

            Write-Log "Getting PrtgSensor template device id for $templateGroupName/$templateDeviceName"
            $templateDeviceId = Get-PrtgDevice -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $templateGroupName -deviceName $templateDeviceName
            if (!$templateDeviceId){
                throw "Unable to get template device id for $templateGroupName/$templateDeviceName"
            }
            Write-Log "PrtgSensor template device id is $templateDeviceId"

            Write-Log "Copying PrtgSensor device from $templateGroupName/$templateDeviceName to $groupName/$deviceName"
            $deviceId = Copy-PrtgDevice -apiUrl $apiUrl -login $login -passwordHash $passwordHash -templateDeviceId $templateDeviceId -groupId $groupId -deviceName $deviceName
            if (!$deviceId){
                throw "Unable to copy device from $templateGroupName/$templateDeviceName to $groupName/$deviceName "
            }
        }
        Write-Log "PrtgSensor device id is $deviceId"


        Write-Log "Getting PrtgSensor template sensor id for $templateGroupName/$templateDeviceName/$templateSensorName"
        $templateSensorId = Get-PrtgSensor -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $templateGroupName -deviceName $templateDeviceName -sensorName $templateSensorName
        if (!$templateSensorId){
            throw "Unable to get template sensor id for $templateGroupName/$templateDeviceName/$templateSensorName"
        }
        Write-Log "PrtgSensor template sensor id is $templateSensorId"

        Write-Log "Copying PrtgSensor sensor from $templateGroupName/$templateDeviceName/$templateSensorName to $groupName/$deviceName/$sensorName"
        $sensorId = Copy-PrtgSensor -apiUrl $apiUrl -login $login -passwordHash $passwordHash -templateSensorId $templateSensorId -deviceId $deviceId -sensorName $sensorName
        if (!$sensorId){
            throw "Unable to copy sensor from $templateGroupName/$templateDeviceName/$templateSensorName to $groupName/$deviceName/$sensorName "
        }
 
        Write-Log "PrtgSensor sensor id is $sensorId"
       
        Write-Log "Setting PrtgSensor sensor property $groupName/$deviceName/$sensorName/exeparams to $sensorParameter"
        $result = Set-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "exeparams" -propertyValue $sensorParameter
        if (!$result){
            throw "Unable to set prtg sensor property $groupName/$deviceName/$sensorName/exeparams set to $sensorParameter"
        } 
        Write-Log "PrtgSensor sensor property $groupName/$deviceName/$sensorName/exeparams set to $sensorParameter"

        if ($sensorTimeout -ne 0){
            Write-Log "Setting PrtgSensor sensor property $groupName/$deviceName/$sensorName/timeout to $sensorParameter"
            $result = Set-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "timeout" -propertyValue $sensorTimeout
            if (!$result){
                throw "Unable to set prtg sensor property $groupName/$deviceName/$sensorName/timeout set to $sensorTimeout"
            } 
            Write-Log "PrtgSensor sensor property $groupName/$deviceName/$sensorName/timeout set to $sensorTimeout"
        }

        $sensorIds=@()
        do
        {
            Write-Log "Check for duplicate sensor id for PrtgSensor for $groupName/$deviceName/$sensorName"
            $sensorIds = Get-PrtgSensors -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName

            if ($sensorIds.Count -gt 1){
                $sensorIds | Sort-Object | select -skip 1 | %{
                    $sensorId = $_
                    Write-Log "Delete PrtgServiceBusSubscribeSensors for $sensorId"
                    Delete-PrtgObject -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId
                }
                Write-Log "Wait 5 seconds and then check again"
                start-sleep -seconds 5
            }
        } while ($sensorIds.Count -gt 1)           
    } else {
        $sensorIds | %{      
            $sensorId = $_    
            Write-Log "Getting PrtgSensor sensor property for $groupName/$deviceName/$sensorName/exeparams"
            $oldSensorParameter = Get-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "exeparams"

            if ($oldSensorParameter -ne $sensorParameter){
                Write-Log "Setting PrtgSensor sensor property $groupName/$deviceName/$sensorName/exeparams to $sensorParameter"
                $result = Set-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "exeparams" -propertyValue $sensorParameter
                if (!$result){
                    throw "Unable to set prtg sensor property $groupName/$deviceName/$sensorName/exeparams set to $sensorParameter"
                } 
                Write-Log "PrtgSensor sensor property $groupName/$deviceName/$sensorName/exeparams set to $sensorParameter"
            }

            if ($sensorTimeout -ne 0){
                Write-Log "Getting PrtgSensor sensor property for $groupName/$deviceName/$sensorName/timeout"
                $oldSensorTimeout = Get-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "timeout"

                if ($oldSensorTimeout -ne $sensorTimeout){
                    Write-Log "Setting PrtgSensor sensor property $groupName/$deviceName/$sensorName/exeparams to $sensorParameter"
                    $result = Set-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "timeout" -propertyValue $sensorTimeout
                    if (!$result){
                        throw "Unable to set prtg sensor property $groupName/$deviceName/$sensorName/timeout set to $sensorTimeout"
                    } 
                    Write-Log "PrtgSensor sensor property $groupName/$deviceName/$sensorName/timeout set to $sensorTimeout"
                }
            }
        }
    }   
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
        $groupName = $sensorConfig.groupName
        $deviceName = $sensorConfig.deviceName
        $sensorName = $sensorConfig.sensorName

        Write-Log "Getting sensor id for PrtgServiceBusSubscribeSensors for $groupName/$deviceName/$sensorName"
        $sensorIds = Get-PrtgSensors -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName

        $sensorIds | %{      
            $sensorId = $_
            Write-Log "Delete PrtgServiceBusSubscribeSensors for $sensorId"
            Delete-PrtgObject -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId
        }
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

    $groupName = $sensorConfig.groupName
    $deviceName = $sensorConfig.deviceName
    $sensorName = $sensorConfig.sensorName

    Write-Log "Getting sensor id for PrtgServiceBusSubscribeSensor for $groupName/$deviceName/$sensorName"
    $sensorIds = Get-PrtgSensors -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName

    $sensorIds | %{      
        $sensorId = $_
        Write-Log "Pause PrtgServiceBusSubscribeSensor for $sensorId"
        Stop-PrtgObject -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -message "Pause for deployment"
    }
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

    $groupName = $sensorConfig.groupName
    $deviceName = $sensorConfig.deviceName
    $sensorName = $sensorConfig.sensorName

    Write-Log "Getting sensor id for PrtgServiceBusSubscribeSensor for $groupName/$deviceName/$sensorName"
    $sensorIds = Get-PrtgSensors -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName

    $sensorIds | %{      
        $sensorId = $_
        Write-Log "Resume PrtgServiceBusSubscribeSensor for $sensorId"
        Start-PrtgObject -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId
    }
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

    $groupName = $sensorConfig.groupName
    $deviceName = $sensorConfig.deviceName
    $sensorName = $sensorConfig.sensorName

    Write-Log "Checking PrtgServiceBusSubscribeSensor for $groupName/$deviceName/$sensorName"
    $sensors = Get-PrtgSensors -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName

    return ($sensors -ne $null)
}

function Get-PrtgSensor {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $apiUrl,     
        [Parameter(Mandatory = $true)]
        [string]
        $login,     
        [Parameter(Mandatory = $true)]
        [string]
        $passwordHash,
        [Parameter(Mandatory = $true)]
        [string]
        $groupName,
        [Parameter(Mandatory = $true)]
        [string]
        $deviceName,
        [Parameter(Mandatory = $true)]
        [string]
        $sensorName
    )

    if (!$apiUrl.EndsWith("/")){
        $apiUrl += "/"
    }

    $url = "$($apiUrl)api/table.json?content=sensors&output=json&columns=objid,group,device,sensor&filter_sensor=$([uri]::EscapeDataString($sensorName))&username=$($login)&passhash=$($passwordHash)"

    $response = Invoke-WebRequestWithoutException -Uri $url

    if (!([int]$response.StatusCode -gt 199 -and [int]$response.StatusCode -lt 300)){
        return $null
    }

    $body = ConvertFrom-Json -InputObject $response.Content

    $matchingSensors = @($body.sensors | ?{$_.group -eq $groupName -and $_.device -eq $deviceName -and $_.sensor -eq $sensorName})

    if (!$matchingSensors){
        return $null
    }

    if ($matchingSensors.Count -gt 1){
        throw "Matches multiple sensors"
    }

    return $matchingSensors[0].objid
}

function Get-PrtgSensors {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $apiUrl,     
        [Parameter(Mandatory = $true)]
        [string]
        $login,     
        [Parameter(Mandatory = $true)]
        [string]
        $passwordHash,
        [Parameter(Mandatory = $true)]
        [string]
        $groupName,
        [Parameter(Mandatory = $true)]
        [string]
        $deviceName,
        [Parameter(Mandatory = $true)]
        [string]
        $sensorName
    )

    if (!$apiUrl.EndsWith("/")){
        $apiUrl += "/"
    }

    $url = "$($apiUrl)api/table.json?content=sensors&output=json&columns=objid,group,device,sensor&filter_sensor=$([uri]::EscapeDataString($sensorName))&username=$($login)&passhash=$($passwordHash)"

    $response = Invoke-WebRequestWithoutException -Uri $url

    if (!([int]$response.StatusCode -gt 199 -and [int]$response.StatusCode -lt 300)){
        return $null
    }

    $body = ConvertFrom-Json -InputObject $response.Content

    $matchingSensors = @($body.sensors | ?{$_.group -eq $groupName -and $_.device -eq $deviceName -and $_.sensor -eq $sensorName})

    if (!$matchingSensors){
        return $null
    }

    return $matchingSensors | %{$_.objid}
}

function Get-PrtgDevice {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $apiUrl,     
        [Parameter(Mandatory = $true)]
        [string]
        $login,     
        [Parameter(Mandatory = $true)]
        [string]
        $passwordHash,
        [Parameter(Mandatory = $true)]
        [string]
        $groupName,
        [Parameter(Mandatory = $true)]
        [string]
        $deviceName
    )

    if (!$apiUrl.EndsWith("/")){
        $apiUrl += "/"
    }   

    $url = "$($apiUrl)api/table.json?content=devices&output=json&columns=objid,group,device&filter_device=$([uri]::EscapeDataString($deviceName))&username=$($login)&passhash=$($passwordHash)"

    $response = Invoke-WebRequestWithoutException -Uri $url

    if (!([int]$response.StatusCode -gt 199 -and [int]$response.StatusCode -lt 300)){
        return $null
    }

    $body = ConvertFrom-Json -InputObject $response.Content

    if (!$body.devices)
    {
        throw "Unable to get prtg device. Response is: $($response.Content)"
    }

    $matchingDevices = @($body.devices | ?{$_.group -eq $groupName -and $_.device -eq $deviceName})

    if (!$matchingDevices){
        return $null
    }

    if ($matchingDevices.Count -gt 1){
        throw "Matches multiple devices"
    }

    return $matchingDevices[0].objid
}

function Get-PrtgGroup {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $apiUrl,     
        [Parameter(Mandatory = $true)]
        [string]
        $login,     
        [Parameter(Mandatory = $true)]
        [string]
        $passwordHash,
        [Parameter(Mandatory = $true)]
        [string]
        $groupName
    )

    if (!$apiUrl.EndsWith("/")){
        $apiUrl += "/"
    }   

    $url = "$($apiUrl)api/table.json?content=groups&output=json&columns=objid,group&filter_group=$([uri]::EscapeDataString($groupName))&username=$($login)&passhash=$($passwordHash)"

    $response = Invoke-WebRequestWithoutException -Uri $url

    if (!([int]$response.StatusCode -gt 199 -and [int]$response.StatusCode -lt 300)){
        return $null
    }

    $body = ConvertFrom-Json -InputObject $response.Content

    if (!$body.groups)
    {
        throw "Unable to get prtg group. Response is: $($response.Content)"
    }

    $matchingGroups = @($body.groups | ?{$_.group -eq $groupName})

    if (!$matchingGroups){
        return $null
    }

    if ($matchingGroups.Count -gt 1){
        throw "Matches multiple groups"
    }

    return $matchingGroups[0].objid
}

function Get-PrtgObjectProperty {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $apiUrl,     
        [Parameter(Mandatory = $true)]
        [string]
        $login,     
        [Parameter(Mandatory = $true)]
        [string]
        $passwordHash,
        [Parameter(Mandatory = $true)]
        [string]
        $objectId,
        [Parameter(Mandatory = $true)]
        [string]
        $propertyName
    )

    if (!$apiUrl.EndsWith("/")){
        $apiUrl += "/"
    }   
            
    $url = "$($apiUrl)api/getobjectproperty.htm?id=$($objectId)&name=$([uri]::EscapeDataString($propertyName))&username=$($login)&passhash=$($passwordHash)"

    $response = Invoke-WebRequestWithoutException -Uri $url

    if (!([int]$response.StatusCode -gt 199 -and [int]$response.StatusCode -lt 300)){
        return $null
    }

    $body =[xml] $response.Content

    $propertyValue = $body.prtg.result;

    return $propertyValue
}

function Copy-PrtgSensor {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $apiUrl,     
        [Parameter(Mandatory = $true)]
        [string]
        $login,     
        [Parameter(Mandatory = $true)]
        [string]
        $passwordHash,
        [Parameter(Mandatory = $true)]
        [string]
        $templateSensorId,
        [Parameter(Mandatory = $true)]
        [string]
        $deviceId,
        [Parameter(Mandatory = $true)]
        [string]
        $sensorName
    )

    if (!$apiUrl.EndsWith("/")){
        $apiUrl += "/"
    }   

    $url = "$($apiUrl)api/duplicateobject.htm?id=$($templateSensorId)&name=$([uri]::EscapeDataString($sensorName))&targetid=$($deviceId)&username=$($login)&passhash=$($passwordHash)"
    $response = Invoke-WebRequestWithoutException -Uri $url -maximumRedirection 0

    if ($url.StartsWith('http://') -and [int]$response.StatusCode -eq 302 -and $response.Headers["Location"] -eq $url.Replace('http://', 'https://')) {
        $response = Invoke-WebRequestWithoutException -Uri $response.Headers["Location"] -maximumRedirection 0
    }

    if ([int]$response.StatusCode -eq 302){
        if ($response.Headers["Location"] -match ".*id=(\d*).*"){
            $sensorId = $response.Headers["Location"] -replace ".*id=(\d*).*", "`$1"

            return $sensorId
        }
    }

    throw "Unable to copy prtg sensor. Response is: $($response.Content)" 
}


function Copy-PrtgDevice {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $apiUrl,     
        [Parameter(Mandatory = $true)]
        [string]
        $login,     
        [Parameter(Mandatory = $true)]
        [string]
        $passwordHash,
        [Parameter(Mandatory = $true)]
        [string]
        $templateDeviceId,
        [Parameter(Mandatory = $true)]
        [string]
        $groupId,
        [Parameter(Mandatory = $true)]
        [string]
        $deviceName
    )

    if (!$apiUrl.EndsWith("/")){
        $apiUrl += "/"
    }   

    $url = "$($apiUrl)api/duplicateobject.htm?id=$($templateDeviceId)&name=$([uri]::EscapeDataString($deviceName))&targetid=$($groupId)&username=$($login)&passhash=$($passwordHash)"
    $response = Invoke-WebRequestWithoutException -Uri $url -maximumRedirection 0

    if ($url.StartsWith('http://') -and [int]$response.StatusCode -eq 302 -and $response.Headers["Location"] -eq $url.Replace('http://', 'https://')) {
        $response = Invoke-WebRequestWithoutException -Uri $response.Headers["Location"] -maximumRedirection 0
    }

    if ([int]$response.StatusCode -eq 302){
        if ($response.Headers["Location"] -match ".*id=(\d*).*"){
            $deviceId = $response.Headers["Location"] -replace ".*id=(\d*).*", "`$1"

            return $deviceId
        }
    }

    throw "Unable to copy prtg device. Response is: $($response.Content)" 
}


function Set-PrtgObjectProperty {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $apiUrl,     
        [Parameter(Mandatory = $true)]
        [string]
        $login,     
        [Parameter(Mandatory = $true)]
        [string]
        $passwordHash,
        [Parameter(Mandatory = $true)]
        [string]
        $objectId,
        [Parameter(Mandatory = $true)]
        [string]
        $propertyName,
        [Parameter(Mandatory = $true)]
        [string]
        $propertyValue
    )

    if (!$apiUrl.EndsWith("/")){
        $apiUrl += "/"
    }   
            
    $url = "$($apiUrl)api/setobjectproperty.htm?id=$($objectId)&name=$([uri]::EscapeDataString($propertyName))&value=$([uri]::EscapeDataString($propertyValue))&username=$($login)&passhash=$($passwordHash)"

    $response = Invoke-WebRequestWithoutException -Uri $url
    $result = [int]$response.StatusCode -gt 199 -and [int]$response.StatusCode -lt 300

    return $result
}

function Delete-PrtgObject {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $apiUrl,     
        [Parameter(Mandatory = $true)]
        [string]
        $login,     
        [Parameter(Mandatory = $true)]
        [string]
        $passwordHash,
        [Parameter(Mandatory = $true)]
        [string]
        $objectId
    )
          
    if (!$apiUrl.EndsWith("/")){
        $apiUrl += "/"
    }          
            
    $url = "$($apiUrl)api/deleteobject.htm?id=$($objectId)&username=$($login)&passhash=$($passwordHash)"

    $response = Invoke-WebRequestWithoutException -Uri $url
    $result = [int]$response.StatusCode -gt 199 -and [int]$response.StatusCode -lt 300

    return $result
}

function Start-PrtgObject {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $apiUrl,     
        [Parameter(Mandatory = $true)]
        [string]
        $login,     
        [Parameter(Mandatory = $true)]
        [string]
        $passwordHash,
        [Parameter(Mandatory = $true)]
        [string]
        $objectId
    )

    if (!$apiUrl.EndsWith("/")){
        $apiUrl += "/"
    }
            
    $url = "$($apiUrl)api/pause.htm?id=$($objectId)&action=1&username=$($login)&passhash=$($passwordHash)"

    $response = Invoke-WebRequestWithoutException -Uri $url
    $result = [int]$response.StatusCode -gt 199 -and [int]$response.StatusCode -lt 300

    return $result
}

function Stop-PrtgObject {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $apiUrl,     
        [Parameter(Mandatory = $true)]
        [string]
        $login,     
        [Parameter(Mandatory = $true)]
        [string]
        $passwordHash,
        [Parameter(Mandatory = $true)]
        [string]
        $objectId,
        [Parameter(Mandatory = $true)]
        [string]
        $message
    )

    if (!$apiUrl.EndsWith("/")){
        $apiUrl += "/"
    }
            
    $url = "$($apiUrl)api/pause.htm?id=$($objectId)&action=0&pausemsg=$([uri]::EscapeDataString($message))&action=0&username=$($login)&passhash=$($passwordHash)"

    $response = Invoke-WebRequestWithoutException -Uri $url
    $result = [int]$response.StatusCode -gt 199 -and [int]$response.StatusCode -lt 300

    return $result
}

function Invoke-WebRequestWithoutException {
    param (
        [string] $Uri,
        $maximumRedirection = 5
    )

    $Uri += "&_=$((Get-Date).Ticks)"

    $request = $null
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $Uri -MaximumRedirection $maximumRedirection -ErrorAction SilentlyContinue
    } 
    catch [System.Net.WebException] {
        if ($_.Exception.Response){
                $response = $_.Exception.Response
        } else {
            throw $_
        }
    }

    return $response
}

