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

function Read-ConfigurationTokens {
    param(        
        [string]$configPath
    )
    
    Write-Verbose "Loading configuration tokens from $configPath"
    return gc -Encoding UTF8 $configPath | Out-String | ConvertFrom-Json
}

function Merge-Tokens {
    param( 
        [string] $template,
        $tokens
    )

    return [regex]::Replace(
        $template,
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
}

function Format-AccountName {
    param(
        [string] $account
    )

    if([string]::IsNullOrEmpty($account)) {
        return $account
    }

    if ($account -eq "Network Service") {
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