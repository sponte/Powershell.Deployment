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

    $templateGroupName = $sensorConfig.templateGroupName
    $templateDeviceName = $sensorConfig.templateDeviceName
    $templateSensorName = $sensorConfig.templateSensorName

    $groupName = $sensorConfig.groupName
    $deviceName = $sensorConfig.deviceName
    $sensorName = $sensorConfig.sensorName

    $sensorTimeout = $sensorConfig.sensorTimeout
    $sensorParameter = "$($sensorConfig.sensorUrl)"

    Write-Log "Getting sensor id for PrtgSensor for $groupName/$deviceName/$sensorName"
    $sensorId = Get-PrtgSensor -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName

    if (!$sensorId){
        Write-Log "Getting PrtgSensor template sensor id for $templateGroupName/$templateDeviceName/$templateSensorName"
        $templateSensorId = Get-PrtgSensor -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $templateGroupName -deviceName $templateDeviceName -sensorName $templateSensorName

        Write-Log "Getting PrtgSensor device id for $groupName/$deviceName"
        $deviceId = Get-PrtgDevice -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName
    
        Write-Log "Copying PrtgSensor sensor from $templateGroupName/$templateDeviceName/$templateSensorName to $groupName/$deviceName/$sensorName"
        $sensorId = Copy-PrtgSensor -apiUrl $apiUrl -login $login -passwordHash $passwordHash -templateSensorId $templateSensorId -deviceId -sensorName $sensorName

        Write-Log "Setting PrtgSensor sensor property $groupName/$deviceName/$sensorName/exeparams to $sensorParameter"
        Set-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "exeparams" -propertyValue $sensorParameter

        if ($sensorTimeout -ne 0){
            Write-Log "Setting PrtgSensor sensor property $groupName/$deviceName/$sensorName/exeparams to $sensorParameter"
            Set-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "timeout" -propertyValue $sensorTimeout
        }
    } else {
        Write-Log "Getting PrtgSensor sensor property for $groupName/$deviceName/$sensorName/exeparams"
        $oldSensorParameter = Get-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "exeparams"

        if ($oldSensorParameter -ne $sensorParameter){
            Write-Log "Setting PrtgSensor sensor property $groupName/$deviceName/$sensorName/exeparams to $sensorParameter"
            Set-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "exeparams" -propertyValue $sensorParameter
        }

        if ($sensorTimeout -ne 0){
            Write-Log "Getting PrtgSensor sensor property for $groupName/$deviceName/$sensorName/timeout"
            $oldSensorTimeout = Get-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "timeout"

            if ($oldSensorTimeout -ne $sensorTimeout){
                Write-Log "Setting PrtgSensor sensor property $groupName/$deviceName/$sensorName/exeparams to $sensorParameter"
                Set-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "timeout" -propertyValue $sensorTimeout
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

        Write-Log "Getting sensor id for PrtgSensor for $groupName/$deviceName/$sensorName"
        $sensorId = Get-PrtgSensor -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName

        Write-Log "Delete PrtgSensor for $sensorId"
        Delete-PrtgObject -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId
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
    $sensorId = Get-PrtgSensor -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName

    Write-Log "Pause PrtgSensor for $sensorId"
    Stop-PrtgObject -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -message "Pause for deployment"
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
    $sensorId = Get-PrtgSensor -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName

    Write-Log "Resume PrtgSensor for $sensorId"
    Start-PrtgObject -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId
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
    $sensor = Get-PrtgSensor -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName

    return ($sensor -ne $null)
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

    Write-Log "Getting sensor id for PrtgServiceBusSubscribeSensors for $groupName/$deviceName/$sensorName"
    $sensorId = Get-PrtgSensor -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName

    if (!$sensorId){
        Write-Log "Getting PrtgServiceBusSubscribeSensor template sensor id for $templateGroupName/$templateDeviceName/$templateSensorName"
        $templateSensorId = Get-PrtgSensor -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $templateGroupName -deviceName $templateDeviceName -sensorName $templateSensorName

        Write-Log "Getting PrtgServiceBusSubscribeSensor device id for $groupName/$deviceName"
        $deviceId = Get-PrtgDevice -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName
    
        Write-Log "Copying PrtgServiceBusSubscribeSensor sensor from $templateGroupName/$templateDeviceName/$templateSensorName to $groupName/$deviceName/$sensorName"
        $sensorId = Copy-PrtgSensor -apiUrl $apiUrl -login $login -passwordHash $passwordHash -templateSensorId $templateSensorId -deviceId -sensorName $sensorName

        Write-Log "Setting PrtgServiceBusSubscribeSensor sensor property $groupName/$deviceName/$sensorName/exeparams to $sensorParameter"
        Set-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "exeparams" -propertyValue $sensorParameter

        if ($sensorTimeout -ne 0){
            Write-Log "Setting PrtgServiceBusSubscribeSensor sensor property $groupName/$deviceName/$sensorName/exeparams to $sensorParameter"
            Set-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "timeout" -propertyValue $sensorTimeout
        }
    } else {
        Write-Log "Getting PrtgServiceBusSubscribeSensor sensor property for $groupName/$deviceName/$sensorName/exeparams"
        $oldSensorParameter = Get-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "exeparams"

        if ($oldSensorParameter -ne $sensorParameter){
            Write-Log "Setting PrtgServiceBusSubscribeSensor sensor property $groupName/$deviceName/$sensorName/exeparams to $sensorParameter"
            Set-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "exeparams" -propertyValue $sensorParameter
        }

        if ($sensorTimeout -ne 0){
            Write-Log "Getting PrtgServiceBusSubscribeSensor sensor property for $groupName/$deviceName/$sensorName/timeout"
            $oldSensorTimeout = Get-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "timeout"

            if ($oldSensorTimeout -ne $sensorTimeout){
                Write-Log "Setting PrtgServiceBusSubscribeSensor sensor property $groupName/$deviceName/$sensorName/exeparams to $sensorParameter"
                Set-PrtgObjectProperty -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -propertyName "timeout" -propertyValue $sensorTimeout
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
        $sensorId = Get-PrtgSensor -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName

        Write-Log "Delete PrtgServiceBusSubscribeSensors for $sensorId"
        Delete-PrtgObject -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId
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
    $sensorId = Get-PrtgSensor -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName

    Write-Log "Pause PrtgServiceBusSubscribeSensor for $sensorId"
    Stop-PrtgObject -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId -message "Pause for deployment"
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
    $sensorId = Get-PrtgSensor -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName

    Write-Log "Resume PrtgServiceBusSubscribeSensor for $sensorId"
    Start-PrtgObject -apiUrl $apiUrl -login $login -passwordHash $passwordHash -objectId $sensorId
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
    $sensor = Get-PrtgSensor -apiUrl $apiUrl -login $login -passwordHash $passwordHash -groupName $groupName -deviceName $deviceName -sensorName $sensorName

    return ($sensor -ne $null)
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

    $url = "$($apiUrl)/api/table.json?content=sensors&output=json&columns=objid,group,device,sensor&filter_sensor=$([uri]::EscapeDataString($sensorName))&username=$($login)&passhash=$($passwordHash)"

    $response = Invoke-WebRequest -UseBasicParsing -Uri $url

    if (!($response.StatusCode -gt 199 -and $response.StatusCode -lt 300)){
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

    $url = "$($apiUrl)/api/table.json?content=devices&output=json&columns=objid,group,device&filter_device=$([uri]::EscapeDataString($deviceName))&username=$($login)&passhash=$($passwordHash)"

    $response = Invoke-WebRequest -UseBasicParsing -Uri $url

    if (!($response.StatusCode -gt 199 -and $response.StatusCode -lt 300)){
        return $null
    }

    $body = ConvertFrom-Json -InputObject $response.Content

    $matchingDevices = @($body.sensors | ?{$_.group -eq $groupName -and $_.device -eq $deviceName})

    if (!$matchingDevices){
        return $null
    }

    if ($matchingDevices.Count -gt 1){
        throw "Matches multiple devices"
    }

    return $matchingDevices[0].objid
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
            
    $url = "$($apiUrl)/api/getobjectproperty.htm?id=$($objectId)&name=$($propertyName)&username=$($login)&passhash=$($passwordHash)"

    $response = Invoke-WebRequest -UseBasicParsing -Uri $url

    if (!($response.StatusCode -gt 199 -and $response.StatusCode -lt 300)){
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

    $url = "$($apiUrl)/api/duplicateobject.htm?id=$($templateSensorId)&name=$([uri]::EscapeDataString($sensorName))&targetid=$($deviceId)&username=$($login)&passhash=$($passwordHash)"
    $response = Invoke-WebRequest -UseBasicParsing -Uri $url

    if ($response.StatusCode -eq 302){
        if ($response.Headers["Location"] -match ".*id=(\d*).*"){
            $sensorId = $response.Headers["Location"] -replace ".*id=(\d*).*", "`$1"

            return $sensorId
        }
    }

    throw new Exception($response.Content)
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
            
    $url = "$($apiUrl)/api/setobjectproperty.htm?id=$($objectId)&name=$($propertyName)&value=$($propertyValue)&username=$($login)&passhash=$($passwordHash)"

    $response = Invoke-WebRequest -UseBasicParsing -Uri $url
    $result = $response.StatusCode -gt 199 -and $response.StatusCode -lt 300

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
            
    $url = "$($apiUrl)/api/deleteobject.htm?id=$($objectId)&username=$($login)&passhash=$($passwordHash)"

    $response = Invoke-WebRequest -UseBasicParsing -Uri $url
    $result = $response.StatusCode -gt 199 -and $response.StatusCode -lt 300

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
            
    $url = "$($apiUrl)/api/pause.htm?id=$($objectId)&username=$($login)&passhash=$($passwordHash)"

    $response = Invoke-WebRequest -UseBasicParsing -Uri $url
    $result = $response.StatusCode -gt 199 -and $response.StatusCode -lt 300

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
            
    $url = "$($apiUrl)/api/pause.htm?id=$($objectId)&pausemsg=$($message)&action=0&username=$($login)&passhash=$($passwordHash)"

    $response = Invoke-WebRequest -UseBasicParsing -Uri $url
    $result = $response.StatusCode -gt 199 -and $response.StatusCode -lt 300

    return $result
}
