[CmdletBinding()]
param(
	[string] $environmentConfigurationFilePath = (Join-Path (Split-Path -parent $MyInvocation.MyCommand.Definition) "deployment_configuration.xml" ),
	[string] $productConfigurationFilePath = (Join-Path (Split-Path -parent $MyInvocation.MyCommand.Definition) "configuration.xml" )
)

$scriptPath = Split-Path -parent $MyInvocation.MyCommand.Definition
Import-Module $scriptPath\PowershellModules\CommonDeploy.psm1 -Force

$rootPath = Split-Path -parent $scriptPath

$e = $environmentConfiguration = Read-ConfigurationTokens $environmentConfigurationFilePath
$p = $productConfiguration = Get-Configuration $environmentConfigurationFilePath $productConfigurationFilePath

Write-Host "Updating configuration at $rootPath using $environmentConfigurationFilePath"

<#
Update-XmlConfig `
	-xmlFile $servicePath\Web.config `
	-xPath "/configuration/connectionStrings/add[@name='Bookings']" `
	-attributeName "connectionString" `
	-value "server=$($e.internal_sql_host);database=ejWorkspace;$($e.sql_authentication_string);Application Name=$($p.configuration.componentName);"
#>