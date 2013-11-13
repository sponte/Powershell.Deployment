$root = Split-Path -parent $MyInvocation.MyCommand.Path

function Contains-NuGetPackage {
	param(
		[string] $packageConfigPath,
		[string] $packageId
	)
		
	[xml] $xml = gc $packageConfigPath
	return $xml.SelectSingleNode("//package[@id='$packageId']") -ne $null
}

function Is-WebProject {
	param(
		[string] $projectPath
	)
	
	$projectFile = gci $projectPath -Name "*.csproj" | Select -First 1
	$projectFile = "$projectPath\$projectFile"
	[xml] $project = gc $projectFile
	
	return ( $project.Project.Import | ?{ $_.Project.Contains("WebApplications") } ) -ne $null
}

function Get-OutputDirectory {
	param (
		[string] $projectPath
	)

	$projectFile = gci $projectPath -Name "*.csproj" | Select -First 1
	$projectFilePath = "$projectPath\$projectFile"
	[xml] $project = gc $projectFilePath

	$outputPath = $project.Project.PropertyGroup | ?{ $_.Condition -and $_.Condition.Contains('Release') } | %{ $_.OutputPath } | select -last 1

	if (!$outputPath)
	{
		$outputPath = "bin\release"
	}
	
	return $outputPath
}

function Get-ProjectsWithNugetPackage {
	param (
		[string] $packageId
	)
	
	return gci $root -Name "packages.config" -Recurse | `
		?{	Contains-NuGetPackage "$root\$_" $packageId } | `
		%{ Split-Path -parent $_ }
}

function Project-Action {
	param(
		[string] $project,
		[string] $action,
		[bool] $failIfNotFound = $true
	)
	
	Write-Host "$($action)ing project $project" -Fore Green

	$envConfpath = "$project\deployment\deployment_configuration.xml"

	$buildPath = [string]::Empty
	if(!(Is-WebProject "$root\$project")) {
		$buildPath = Get-OutputDirectory -project "$root\$project"
	}
	
	$scriptFile =  "$root\$project\$buildPath\Deployment\$action.ps1"

	$scriptExists = (Test-Path $scriptFile)

	if(!$scriptExists -and $failIfNotFound) {
		throw "Could not find script $scriptFile"
	}
	
	if($scriptExists) {
		if([string]::IsNullOrEmpty($envConfpath)) {
			& $scriptFile
		} else {
			& $scriptFile $envConfPath
		}
	}
}	

$projects = Get-ProjectsWithNugetPackage "easyJet.Deployment.Scripts"

function Download-DeploymentConfiguration {
	param(
			[string] $project
		)

	$deployConf = "$project\deployment\deployment_configuration.xml"
	$latestdeployConf = "$project\deployment\latest_deployment_configuration.xml"

	Remove-Item $latestdeployConf -Force -ErrorAction SilentlyContinue	
	try {
	(
		new-object system.net.webclient).DownloadFile("http://ads/TeamCity/DownloadConfigForEnvironmentName?environmentName=localhost", $latestdeployConf)
		Remove-Item $deployConf -Force -ErrorAction SilentlyContinue
		Move-Item $latestdeployConf $deployConf
	} catch {		
	}
}

$projects | %{ Download-DeploymentConfiguration $_ }
$projects | %{ Project-Action $_ "stop" $false }
$projects | %{ Project-Action $_ "uninstall" $false }

& "$($env:windir)\microsoft.net\framework\v4.0.30319\msbuild.exe" "$root\scripts\InitialSetup.proj"

$projects | %{ Project-Action $_ "install" }
$projects | %{ Project-Action $_ "start"  }
