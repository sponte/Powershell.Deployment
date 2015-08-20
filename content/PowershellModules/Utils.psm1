function Get-ValidationXsdPath {
    $root = $null

    if (!$root -and $PSScriptRoot)
    {
        $root = $PSScriptRoot
    }

    if (!$root -and $PSCommandPath)
    {
        $root = Split-Path -parent $PSCommandPath
    }

    if (!$root -and $script:MyInvocation.MyCommand.Path)
    {
        $root = Split-Path $script:MyInvocation.MyCommand.Path
    }

    if (!$root -and $MyInvocation.MyCommand.Definition)
    {
        $root = split-path -parent $MyInvocation.MyCommand.Definition
    }

    if (!$root) {
        $root = ".\"
    }

    $path = (Join-Path $root "configuration.xsd")

    return $path
}

function Encrypt-Envelope($unprotectedcontent, $cert)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.Security") | Out-Null
    $utf8content = [Text.Encoding]::UTF8.GetBytes($unprotectedcontent)
    $content = New-Object Security.Cryptography.Pkcs.ContentInfo -argumentList (,$utf8content)
    $env = New-Object Security.Cryptography.Pkcs.EnvelopedCms $content
    $recpient = (New-Object System.Security.Cryptography.Pkcs.CmsRecipient($cert))
    $env.Encrypt($recpient)
    $base64string = [Convert]::ToBase64String($env.Encode())
    return $base64string
}

function Decrypt-Envelope($base64string)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.Security") | Out-Null
    $content = [Convert]::FromBase64String($base64string)
    $env = New-Object Security.Cryptography.Pkcs.EnvelopedCms
    $env.Decode($content)
    $env.Decrypt()
    $utf8content = [text.encoding]::UTF8.getstring($env.ContentInfo.Content)
    return $utf8content
}

function Write-Log {
    $str = $args -join " "
    Write-Host "[Log] $str" -Foreground Magenta
}

function Sync-Directory {
    param(        
        $sourcePath,         
        $destinationPath        
    )
    
    &robocopy "$sourcePath" "$destinationPath" /MIR
}

function Update-XmlConfig {
    param(   
        [string]$xmlFile,
        [string]$xPath,
        [string]$value,
        [string]$attributeName
    )
    
    [xml]$xml = Get-Content -Encoding UTF8 $xmlFile

    $nodes = $xml.SelectNodes($xPath)
    
    foreach($node in $nodes) {
                    if($attributeName -eq "") {
                                    $node.InnerText = $value
                    } else {
                                    $node.SetAttribute($attributeName, $value)
                    }
    }
    
    $xml.Save($xmlFile)
}

function Update-TextConfig {
    param(   
        [string]$textFile,
        [string]$search,
        [string]$replace
    )

    $c = gc -Encoding UTF8 $textFile
    
    $c | % { $_ -replace $search,$replace } | sc -Path $textFile
}

function Update-PropertiesConfig {
    param(   
        [string]$propertiesFile,
        [string]$key,
        [string]$value,
        [string]$seperator = ':'
    )
    
    $c = Get-Content -Encoding UTF8 $propertiesFile

    $c | % { $_ -replace "($key\s*$seperator\s*)(.*)", "`${1}$value" } | sc -Path $propertiesFile
}

function Get-Configuration {
    param(        
        [Parameter(Mandatory = $true)]
        [string]
        $environmentConfigurationFilePath,
        [Parameter(Mandatory = $true)]
        [string]
        $productConfigurationFilePath
    )

    # Read in configuration template
    $configurationTemplate = Read-ConfigurationTemplate($productConfigurationFilePath)
    
    $configurationTemplate = Set-ConfigurationTemplateDefaultsForSites $configurationTemplate
    $configurationTemplate = Set-ConfigurationTemplateDefaultsForNServiceBus $configurationTemplate
    $configurationTemplate = Set-ConfigurationTemplateDefaultsForWindowsService $configurationTemplate
    $configurationTemplate = Set-ConfigurationTemplateDefaultsForTopshelfService $configurationTemplate
    $configurationTemplate = Set-ConfigurationTemplateDefaultsForCertificates $configurationTemplate
    $configurationTemplate = Set-ConfigurationTemplateDefaultsForFilePermissions $configurationTemplate
    
    # Read in configuration tokens
    $configurationTokens = Read-ConfigurationTokens($environmentConfigurationFilePath)
    
    # Apply setting transformations as a merge
    $configurationTemplate = Merge-Tokens -template $configurationTemplate -tokens $configurationTokens
    
    Write-Verbose $configurationTemplate
    
    $xmlConf = [xml]$configurationTemplate
    
    $validationXsd = Get-ValidationXsdPath
    $schemaReader = [System.Xml.XmlReader]::Create($validationXsd)
    $schemas = $xmlConf.Schemas.Add("", $schemaReader)
    $xmlConf.Validate($null)

    $schemaReader.Close()
    
    return $xmlConf
}

function Set-ConfigurationTemplateDefaultsForSites {
    param(
        $xmlString
    )
    
    [xml]$xml = $xmlString
    $validationXsd = Get-ValidationXsdPath
    $schemaReader = [System.Xml.XmlReader]::Create($validationXsd)
    $schemas = $xml.Schemas.Add("", $schemaReader)
    $xml.Validate($null)
    $schemaReader.Close()
        
    $sites = $xml.SelectNodes("//site")
    $componentName = $xml.configuration.componentName

    foreach($siteConfig in $sites) {
       if(!$siteConfig) { continue }

        $appPoolConfig = $siteConfig.appPool
    
        if($appPoolConfig -eq $null) {
            $appPoolConfig = $siteConfig.OwnerDocument.CreateElement("appPool")
            $appPoolConfig.SetAttribute("name", $siteConfig.name)
            
            $accountElement = $siteConfig.OwnerDocument.CreateElement("account")
            $accountElement.InnerText = ""
            $passwordElement = $siteConfig.OwnerDocument.CreateElement("password")
            $passwordElement.InnerText = ""

            $appPoolConfig.AppendChild($accountElement) | Out-Null
            $appPoolConfig.AppendChild($passwordElement) | Out-Null

            $siteConfig.AppendChild($appPoolConfig)  | Out-Null
        }
        
        if (!$siteConfig.Bindings)
        {
            $bindings = $siteConfig.OwnerDocument.CreateElement("bindings")
            
            # HTTP binding port 80 (External host header)
            $bindingWithHostHeader = $siteConfig.OwnerDocument.CreateElement("binding")
            $bindingWithHostHeader.SetAttribute("protocol", "http")
            $bindingWithHostHeader.SetAttribute("information", "*:80:")
            $bindings.AppendChild($bindingWithHostHeader) | Out-Null

            $siteConfig.AppendChild($bindings)   | Out-Null
        }
        
        if ($siteConfig.containerOnly -eq $true -and -not $siteConfig.applications)
        {
            $applications = $siteConfig.OwnerDocument.CreateElement("applications")
            $application = $siteConfig.OwnerDocument.CreateElement("application")
            $application.SetAttribute("alias", $componentName)
            $applications.AppendChild($application)  | Out-Null
            $siteConfig.AppendChild($applications)   | Out-Null
        }
    }
    
    $apps = $xml.SelectNodes("//application")

    foreach($appConfig in $apps) {
       if(!$appConfig) { continue }

        $appPoolConfig = $appConfig.appPool
    
        if($appPoolConfig -eq $null) {
            $appPoolConfig = $appConfig.OwnerDocument.CreateElement("appPool")
            $appPoolConfig.SetAttribute("name", $appConfig.alias)
            
            $accountElement = $appConfig.OwnerDocument.CreateElement("account")
            $accountElement.InnerText = ""
            $passwordElement = $appConfig.OwnerDocument.CreateElement("password")
            $passwordElement.InnerText = ""

            $appPoolConfig.AppendChild($accountElement) | Out-Null
            $appPoolConfig.AppendChild($passwordElement) | Out-Null

            $appConfig.AppendChild($appPoolConfig)   | Out-Null
        }
    }
    
    return $xml.OuterXML
}

function Set-ConfigurationTemplateDefaultsForNServiceBus {
    param(
        $xmlString
    )
    
    [xml]$xml = $xmlString
    $validationXsd = Get-ValidationXsdPath
    $schemaReader = [System.Xml.XmlReader]::Create($validationXsd)
    $schemas = $xml.Schemas.Add("", $schemaReader)
    $xml.Validate($null)
    $schemaReader.Close()
    
    $nServiceBuses = @($xml.SelectNodes("//services/NServiceBus"))
    $componentName = $xml.configuration.componentName

    $firstNServiceBus = $nServiceBuses | Select -First 1
    
    if($firstNServiceBus) {
        $nServiceBus = $firstNServiceBus
        
        if(-not $nServiceBus.SelectSingleNode("name")) {
            $element = $nServiceBus.OwnerDocument.CreateElement("name")
            $element.InnerText = $componentName
            $nServiceBus.AppendChild($element) | Out-Null
        }
        if(-not $nServiceBus.displayName) {
            $element = $nServiceBus.OwnerDocument.CreateElement("displayName")
            $element.InnerText = $componentName
            $nServiceBus.AppendChild($element) | Out-Null
        }
    }
    
    foreach($nServiceBus in $nServiceBuses) {
        if(!$nServiceBus) { continue }
    
        if($nServiceBus.account -eq $null) {
            $element = $nServiceBus.OwnerDocument.CreateElement("account")
            $element.InnerText = ""
            $nServiceBus.AppendChild($element) | Out-Null
        }
        if($nServiceBus.password -eq $null) {
            $element = $nServiceBus.OwnerDocument.CreateElement("password")
            $element.InnerText = ""
            $nServiceBus.AppendChild($element) | Out-Null
        }
        if($nServiceBus.serviceStartupType -eq $null) {
            $element = $nServiceBus.OwnerDocument.CreateElement("serviceStartupType")
            $element.InnerText = "delayed-auto"
            $nServiceBus.AppendChild($element) | Out-Null
        }
        
        if($nServiceBus.profiles -eq $null) {
            $profilesElement = $nServiceBus.OwnerDocument.CreateElement("profiles")
            $productionElement = $nServiceBus.OwnerDocument.CreateElement("profile")
            $performanceCountersElement = $nServiceBus.OwnerDocument.CreateElement("profile")
            
            $productionElement.InnerText = "NServiceBus.Production"
            $performanceCountersElement.InnerText = "NServiceBus.PerformanceCounters"
            
            $profilesElement.AppendChild($productionElement)     | Out-Null
            $profilesElement.AppendChild($performanceCountersElement)    | Out-Null
            $nServiceBus.AppendChild($profilesElement)   | Out-Null
        }

        if($nServiceBus.queues -eq $null) {
            $queuesElement = $nServiceBus.OwnerDocument.CreateElement("queues")
            $queueElement = $nServiceBus.OwnerDocument.CreateElement("queue")
            
            $regexString = ($componentName -split "\.")[1] -replace "s$", ""
            $queueElement.InnerText = $regexString
            $queuesElement.AppendChild($queueElement)    | Out-Null
            
            $nServiceBus.AppendChild($queuesElement)     | Out-Null
        }
    }
    return $xml.OuterXML
}

function Set-ConfigurationTemplateDefaultsForWindowsService {
    param(
        $xmlString
    )
    
    [xml]$xml = $xmlString
    $validationXsd = Get-ValidationXsdPath
    $schemaReader = [System.Xml.XmlReader]::Create($validationXsd)
    $schemas = $xml.Schemas.Add("", $schemaReader)
    $xml.Validate($null)
    $schemaReader.Close()
    
    $WindowsServices = @($xml.SelectNodes("//services/WindowsService"))
    $componentName = $xml.configuration.componentName

    $firstWindowsService = $WindowsServices | Select -First 1
    
    if($firstWindowsService) {
        $WindowsService = $firstWindowsService
        
        if(-not $WindowsService.SelectSingleNode("name")) {
            $element = $WindowsService.OwnerDocument.CreateElement("name")
            $element.InnerText = $componentName
            $WindowsService.AppendChild($element) | Out-Null
        }
        if(-not $WindowsService.displayName) {
            $element = $WindowsService.OwnerDocument.CreateElement("displayName")
            $element.InnerText = $componentName
            $WindowsService.AppendChild($element) | Out-Null
        }

        if(-not $WindowsService.path) {
            $path = ".\" + $WindowsService.SelectSingleNode("name").InnerText + ".exe"
            $WindowsService.SetAttribute("path", $path)
        }
    }
    
    foreach($WindowsService in $WindowsServices) {
        if(!$WindowsService) { continue }
    
        if($WindowsService.account -eq $null) {
            $element = $WindowsService.OwnerDocument.CreateElement("account")
            $element.InnerText = ""
            $WindowsService.AppendChild($element) | Out-Null
        }
        if($WindowsService.password -eq $null) {
            $element = $WindowsService.OwnerDocument.CreateElement("password")
            $element.InnerText = ""
            $WindowsService.AppendChild($element) | Out-Null
        }
        if($WindowsService.serviceStartupType -eq $null) {
            $element = $WindowsService.OwnerDocument.CreateElement("serviceStartupType")
            $element.InnerText = "delayed-auto"
            $WindowsService.AppendChild($element) | Out-Null
        }

        #Must be the last element to pass xsd validation
        if($WindowsService.dependsOnServices -ne $null) {
            $element = $WindowsService.dependsOnServices
            $WindowsService.AppendChild($element) | Out-Null
        }        
    }

    return $xml.OuterXML
}

function Set-ConfigurationTemplateDefaultsForTopshelfService {
    param(
        $xmlString
    )
    [xml]$xml = $xmlString
    $validationXsd = Get-ValidationXsdPath
    $schemaReader = [System.Xml.XmlReader]::Create($validationXsd)
    $schemas = $xml.Schemas.Add("", $schemaReader)
    $xml.Validate($null)
    $schemaReader.Close()

    $WindowsServices = @($xml.SelectNodes("//services/TopshelfService"))
    $componentName = $xml.configuration.componentName
    $firstWindowsService = $WindowsServices | Select -First 1
    if($firstWindowsService) {
        $WindowsService = $firstWindowsService
        if(-not $WindowsService.SelectSingleNode("name")) {
            $element = $WindowsService.OwnerDocument.CreateElement("name")
            $element.InnerText = $componentName
            $WindowsService.AppendChild($element) | Out-Null
        }
        if(-not $WindowsService.displayName) {
            $element = $WindowsService.OwnerDocument.CreateElement("displayName")
            $element.InnerText = $componentName
            $WindowsService.AppendChild($element) | Out-Null
        }
        if(-not $WindowsService.path) {
            $path = ".\" + $WindowsService.SelectSingleNode("name").InnerText + ".exe"
            $WindowsService.SetAttribute("path", $path)
        }
    }
    foreach($WindowsService in $WindowsServices) {
        if(!$WindowsService) { continue }
        if($WindowsService.account -eq $null) {
            $element = $WindowsService.OwnerDocument.CreateElement("account")
            $element.InnerText = ""
            $WindowsService.AppendChild($element) | Out-Null
        }
        if($WindowsService.password -eq $null) {
            $element = $WindowsService.OwnerDocument.CreateElement("password")
            $element.InnerText = ""
            $WindowsService.AppendChild($element) | Out-Null
        }
        if($WindowsService.serviceStartupType -eq $null) {
            $element = $WindowsService.OwnerDocument.CreateElement("serviceStartupType")
            $element.InnerText = "delayed-auto"
            $WindowsService.AppendChild($element) | Out-Null
        }
    }
    return $xml.OuterXML
}

function Set-ConfigurationTemplateDefaultsForCertificates {
    param(
        $xmlString
    )
    [xml]$xml = $xmlString
    $validationXsd = Get-ValidationXsdPath
    $schemaReader = [System.Xml.XmlReader]::Create($validationXsd)
    $schemas = $xml.Schemas.Add("", $schemaReader)
    $xml.Validate($null)
    $schemaReader.Close()

    $certificates = $xml.SelectNodes("//certificate")

    return $xml.OuterXML
}

function Set-ConfigurationTemplateDefaultsForFilePermissions {
    param(
        $xmlString
    )
    [xml]$xml = $xmlString
    $validationXsd = Get-ValidationXsdPath
    $schemaReader = [System.Xml.XmlReader]::Create($validationXsd)
    $schemas = $xml.Schemas.Add("", $schemaReader)
    $xml.Validate($null)
    $schemaReader.Close()

    $certificates = $xml.SelectNodes("//filePermissions")

    return $xml.OuterXML
}

function Read-ConfigurationTemplate {
    param(
        [string]$configPath
    )

    Write-Verbose "Loading configuration template from $configPath"
    return [string]::Join("`n", (gc -Encoding UTF8 $configPath))
}

function Test-JsonString {
    param(        
        [string]$jsonString
    )

    try {
        $temp = $jsonString | ConvertFrom-Json
        return $true
    } catch {
        return $false
    }
}

function Read-ConfigurationTokens {
    param(        
        [string]$configPath
    )
    
    Write-Verbose "Loading configuration tokens from $configPath"

    $configuration = gc -Encoding UTF8 $configPath | Out-String | ConvertFrom-Json

    $configuration | gm | ?{$_.MemberType -eq "NoteProperty"} | %{
       if (Test-Path "env:\$($_.Name)") {
            $settingValue = (get-item "env:$($_.Name)").Value
            if ($settingValue -is "String" -and (Test-JsonString -jsonString $settingValue)) {
                $settingValue = $settingValue | Out-String | ConvertFrom-Json
            }
            $configuration."$($_.Name)" =  $settingValue 
        }
        if (Test-Path "variable:\$($_.Name)") {
            $settingValue = Get-Variable -Name $_.Name -ValueOnly
            if ($settingValue -is "String" -and (Test-JsonString -jsonString $settingValue)) {
                $settingValue = $settingValue | Out-String | ConvertFrom-Json
            }
            $configuration."$($_.Name)" = $settingValue
        }
    }

    return $configuration
}

function Merge-Tokens {
    param( 
        [string] $template,
        $tokens
    )

    $tokensMerged = [regex]::Replace(
        $template,
        '\{\{\s*(?<tokenName>[\$].+?)\s*\}\}',
        {
            param($match)
            $tokenExpression = $match.Groups['tokenName'].Value
            $replacement = iex $tokenExpression
            return $replacement
    })

    $tokensMerged = [regex]::Replace(
        $tokensMerged,
        '\{\{\s*(?<tokenName>[^\$]+?)\s*\}\}',
        {
            param($match)

            $tokenName = $match.Groups['tokenName'].Value
            $replacement = iex "`$tokens.$tokenName"

            if($replacement -eq $null) {
                throw "Could not find replacement token for $tokenName"
            }
            
            return $replacement
    })  

    return $tokensMerged
}

function Get-SecurityIdentifier {
	param(
		[Parameter(Mandatory = $true)]
		[string]
		$username
	)

	if ($username -eq "Administrator"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::AccountAdministratorSid, $null)
	}
	elseif ($username -eq "Computer"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::AccountComputersSid, $null)
	}
	elseif ($username -eq "Controller"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::AccountControllersSid, $null)
	}
	elseif ($username -eq "DomainAdmins"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::AccountDomainAdminsSid, $null)
	}
	elseif ($username -eq "DomainGuests"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::AccountDomainGuestsSid, $null)
	}
	elseif ($username -eq "DomainUsers"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::AccountDomainUsersSid, $null)
	}
	elseif ($username -eq "EnterpriseAdmins"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::AccountEnterpriseAdminsSid, $null)
	}
	elseif ($username -eq "Guest"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::AccountGuestSid, $null)
	}
	elseif ($username -eq "Krbtgt"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::AccountKrbtgtSid, $null)
	}
	elseif ($username -eq "PolicyAdmins"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::AccountPolicyAdminsSid, $null)
	}
	elseif ($username -eq "RasAndIasServers"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::AccountRasAndIasServersSid, $null)
	}
	elseif ($username -eq "Anonymous"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::AnonymousSid, $null)
	}
	elseif ($username -eq "Batch"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::BatchSid, $null)
	}
	elseif ($username -eq "AccountOperators"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::BuiltinAccountOperatorsSid, $null)
	}
	elseif ($username -eq "BuiltinAdministrators"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid, $null)
	}
	elseif ($username -eq "BuiltinAuthorizationAccess"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::BuiltinAuthorizationAccessSid, $null)
	}
	elseif ($username -eq "BuiltinBackupOperators"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::BuiltinBackupOperatorsSid, $null)
	}
	elseif ($username -eq "BuiltinDomain"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::BuiltinDomainSid, $null)
	}
	elseif ($username -eq "BuiltinGuests"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::BuiltinGuestsSid, $null)
	}
	elseif ($username -eq "BuiltinIncomingForestTrustBuilders"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::BuiltinIncomingForestTrustBuildersSid, $null)
	}
	elseif ($username -eq "BuiltinNetworkConfigurationOperators"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::BuiltinNetworkConfigurationOperatorsSid, $null)
	}
	elseif ($username -eq "BuiltinPerformanceLoggingUsers"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::BuiltinPerformanceLoggingUsersSid, $null)
	}
	elseif ($username -eq "BuiltinPerformanceMonitoringUsers"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::BuiltinPerformanceMonitoringUsersSid, $null)
	}
	elseif ($username -eq "BuiltinPowerUsers"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::BuiltinPowerUsersSid, $null)
	}
	elseif ($username -eq "BuiltinPreWindows2000CompatibleAccess"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::BuiltinPreWindows2000CompatibleAccessSid, $null)
	}
	elseif ($username -eq "BuiltinPrintOperators"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::BuiltinPrintOperatorsSid, $null)
	}
	elseif ($username -eq "BuiltinRemoteDesktopUsers"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::BuiltinRemoteDesktopUsersSid, $null)
	}
	elseif ($username -eq "BuiltinReplicator"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::BuiltinReplicatorSid, $null)
	}
	elseif ($username -eq "BuiltinSystemOperators"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::BuiltinSystemOperatorsSid, $null)
	}
	elseif ($username -eq "BuiltinUsers"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::BuiltinUsersSid, $null)
	}
	elseif ($username -eq "CreatorGroupServer"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::CreatorGroupServerSid, $null)
	}
	elseif ($username -eq "CreatorGroup"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::CreatorGroupSid, $null)
	}
	elseif ($username -eq "CreatorOwnerServer"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::CreatorOwnerServerSid, $null)
	}
	elseif ($username -eq "CreatorOwner"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::CreatorOwnerSid, $null)
	}
	elseif ($username -eq "Dialup"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::DialupSid, $null)
	}
	elseif ($username -eq "DigestAuthentication"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::DigestAuthenticationSid, $null)
	}
	elseif ($username -eq "EnterpriseControllers"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::EnterpriseControllersSid, $null)
	}
	elseif ($username -eq "Interactive"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::InteractiveSid, $null)
	}
	elseif ($username -eq "LocalService"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::LocalServiceSid, $null)
	}
	elseif ($username -eq "Local"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::LocalSid, $null)
	}
	elseif ($username -eq "LocalSystem"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::LocalSystemSid, $null)
	}
	elseif ($username -eq "LogonIds"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::LogonIdsSid, $null)
	}
	elseif ($username -eq "MaxDefined"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::MaxDefined, $null)
	}
	elseif ($username -eq "NetworkService"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::NetworkServiceSid, $null)
	}
	elseif ($username -eq "Network"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::NetworkSid, $null)
	}
	elseif ($username -eq "NTAuthority"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::NTAuthoritySid, $null)
	}
	elseif ($username -eq "NtlmAuthentication"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::NtlmAuthenticationSid, $null)
	}
	elseif ($username -eq "Null"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::NullSid, $null)
	}
	elseif ($username -eq "OtherOrganization"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::OtherOrganizationSid, $null)
	}
	elseif ($username -eq "Proxy"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::ProxySid, $null)
	}
	elseif ($username -eq "RemoteLogonId"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::RemoteLogonIdSid, $null)
	}
	elseif ($username -eq "RestrictedCode"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::RestrictedCodeSid, $null)
	}
	elseif ($username -eq "SChannelAuthentication"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::SChannelAuthenticationSid, $null)
	}
	elseif ($username -eq "Self"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::SelfSid, $null)
	}
	elseif ($username -eq "Service"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::ServiceSid, $null)
	}
	elseif ($username -eq "TerminalServer"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::TerminalServerSid, $null)
	}
	elseif ($username -eq "ThisOrganization"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::ThisOrganizationSid, $null)
	}
	elseif ($username -eq "WinBuiltinTerminalServerLicenseServers"){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::WinBuiltinTerminalServerLicenseServersSid, $null)
	}
	elseif (($username -eq "World") -or ($username -eq "Everyone")){
		return New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::WorldSid, $null)
	}
	else {
		return $null
	}
}

function Format-AccountName {
    param(
        [string] $account
    )

    if([string]::IsNullOrEmpty($account)) {
        return $account
    }

    if ($account -eq "Everyone") {
        return $account
    }

    if ($account -eq "LocalService" -or $account -eq "Local Service") {
        return $account
    }

    if ($account -eq "LocalSystem" -or $account -eq "Local System") {
        return $account
    }

    if ($account -eq "Network Service" -or $account -eq "NetworkService") {
        return $account
    }

    if ($account -eq "Application Pool Identity" -or $account -eq "ApplicationPoolIdentity") {
        return $account
    }

    if(-not $account.Contains("\")) {
        $account = ".\$account"
    }

    [regex]::Replace($account, "^\.", $ENV:COMPUTERNAME)
}

function Install-Util {
    param(
        [string] $assemblyFilePath
    )

    &"$env:SystemRoot\Microsoft.NET\Framework64\v4.0.30319\installutil.exe" /i "$assemblyFilePath"
        if($LASTEXITCODE -ne 0) {
            throw "installutil.exe raised an error, please review log messages"
        }
}

function Uninstall-Util {
    param(
        [string] $assemblyFilePath
    )

    &"$env:SystemRoot\Microsoft.NET\Framework64\v4.0.30319\installutil.exe" /u "$assemblyFilePath"
        if($LASTEXITCODE -ne 0) {
            throw "installutil.exe raised an error, please review log messages"
        }
}

function Get-MetaDataFromAssembly {
    param(
        [string] $assemblyFilePath
    )

    $file = Get-ChildItem $assemblyFilePath
    
    $metaData = @{
        FullName=$file.FullName
        FileVersion=$file.VersionInfo.FileVersion;
        ProductVersion=$file.VersionInfo.ProductVersion;
        ProductName = $file.VersionInfo.ProductName;
    }

    $metaData
}

function Test-JsonString {
    param(        
    [string]$jsonString
    )

    try {
        $temp = $jsonString | ConvertFrom-Json
        return $true
    } catch {
        return $false
    }
}

function Test-IisIncrementalSiteIdCreation {
    $registryEntry = Get-ItemProperty 'HKLM:\Software\Microsoft\Inetmgr\Parameters\'
    if ($registryEntry.IncrementalSiteIDCreation -eq "1") {
        return $true
    } else {
        return $false
    }
}

function Set-IisIncrementalSiteIdCreation {
    param(
        [bool] $value
    )

    if ($value -eq (Test-IisIncrementalSiteIdCreation)) {
        return
    }

    if ($value) {
        Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Inetmgr\Parameters\' -Name IncrementalSiteIDCreation -Value 1
    } else {
        Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Inetmgr\Parameters\' -Name IncrementalSiteIDCreation -Value 0
    }

    Restart-Service W3SVC,WAS -force
}

