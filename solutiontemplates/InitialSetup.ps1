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

	$envConfpath = "$project\deployment\deployment_configuration.json"

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

$projects = Get-ProjectsWithNugetPackage "Powershell.Deployment"

$projects | %{ Project-Action $_ "stop" $false }
$projects | %{ Project-Action $_ "uninstall" $false }

$projects | %{ Project-Action $_ "install" }
$projects | %{ Project-Action $_ "start"  }
