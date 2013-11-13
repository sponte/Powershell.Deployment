param($installPath, $toolsPath, $package, $project)

function Install-Item {
    param(
		$template,
		$installPath,
		$project
	)
	
	$deploymentFolder = $project.ProjectItems.Item("Deployment")
	if($deploymentFolder -eq $null) {
		throw "Deployment folder does not exist, aborting installation"
	}
	
	$item = $deploymentFolder.ProjectItems | ?{ $_.Name.Equals($template.Name) }
	if ($item -eq $null)
	{
		# Add a project item from a file.
		$deploymentFolder.ProjectItems.AddFromFileCopy("$installPath\templates\$($template.Name)")
		$item = $deploymentFolder.ProjectItems.Item($template.Name)
	}
}

function Get-SolutionPath {
	param(
		$path
	)
	
	Write-Host "Looking for solution path: $path"

	if ([String]::IsNullOrEmpty(($path)))
	{
		throw "Cannot find solution file, aborting installation"
	}
	
	$solutionFile = gci $path -Filter *.sln
	
	if ($solutionFile)
	{
		Write-Host "Solution path: $path"
		return $path
	}
	
	return Get-SolutionPath -path (Split-Path $path)
}

function Install-SolutionItem {
    param(
		$solutionTemplate,
		$solutionPath
	)
	
	$filename = ([io.fileinfo]$solutionTemplate).name
	$destinationPath = join-path $solutionPath $filename
	
	if (!(Test-Path $destinationPath))
	{
		copy-item $solutionTemplate.FullName $destinationPath
	} else
	{
		Write-Verbose "$destinationPath already exists! So ignoring"
	}
}

function Set-ProjectItem-Property {
	param (
		$item,
		$propertyName,
		$propertyValue
	)
		
	$property = $item.Properties | ?{ $_.Name.Equals($propertyName) }
	if($property -ne $null) {
		$property.Value = $propertyValue
	}	
}

function Set-ProjectItem-CopyToOutputFlag {
	param (
		$projectItems,
		$isWebProject
	)
		
	foreach($item in $projectItems) {
		if(-not $isWebProject) {
			Set-ProjectItem-Property $item "CopyToOutputDirectory" 2
		}
		Set-ProjectItem-Property $item "BuildAction" 2
		
		Set-ProjectItem-CopyToOutputFlag $item.ProjectItems $isWebProject
	}
}

function Set-CopyToOutputForFolder {
	param (
		$project,
		[string] $folderPath,
		$isWebProject
	)
	
	$folderTokens = $folderPath -split "\\"
	
	$folder = $project
	foreach($folderToken in $folderTokens) {
		$folder = $folder.ProjectItems | ?{ $_.Name.Equals($folderToken) }
		if($folder -eq $null) {
			throw "Cannot find part of the path $folderPath"
		}
	}
	
	if($folder -eq $project) {
		throw "You cannot set all files in the project to output"
	}
	
	Set-ProjectItem-CopyToOutputFlag $folder.ProjectItems $isWebProject
}

$templates = gci "$installPath\templates" -rec | where { ! $_.PSIsContainer }
foreach ($template in $templates)
{	
	Install-Item -template $template -installPath $installPath -project $project
}

$solutionPath = Get-SolutionPath -path (split-path $project.FullName)
$solutionTemplates = gci "$installPath\solutiontemplates" -rec | where { ! $_.PSIsContainer }
foreach ($solutionTemplate in $solutionTemplates)
{	
	Install-SolutionItem -solutionTemplate $solutionTemplate -solutionPath $solutionPath
}

$isWebProject = (($project.Properties | ?{ $_.Name.Equals("WebApplication.StartWorkingDirectory") }) -ne $null)
$isTopshelf = ($project.Object.References | ?{ $_.Identity -eq "Topshelf" }) -ne $null
$isNServiceBus = ($project.Object.References | ?{ $_.Identity -eq "NServiceBus.Host" }) -ne $null

$isWindowsService = !$isWebProject -and !$isTopshelf -and !$isNServiceBus

Set-CopyToOutputForFolder $project "Deployment" $isWebProject

$xmlPath = $project.ProjectItems.Item("Deployment").ProjectItems.Item("configuration.xml").Properties.Item("FullPath").Value
[xml] $xml = gc $xmlPath
 
$xml.configuration.componentName = $project.Name
 
if($isWebProject) {
	if (!$xml.configuration.sites)
	{
		$sitesElement = $xml.CreateElement("sites")
		$siteElement = $xml.CreateElement("site")
		$sitesElement.AppendChild($siteElement)
		$xml.configuration.AppendChild($sitesElement)
		$xml.Save($xmlPath)
	}
}

if($isNServiceBus) {
	if (!$xml.configuration.services)
	{
		$servicesElement = $xml.CreateElement("services")
		$nServiceBusElement = $xml.CreateElement("NServiceBus")
		$servicesElement.AppendChild($nServiceBusElement)
		$xml.configuration.AppendChild($servicesElement)
		$xml.Save($xmlPath)
	}
}

if($isTopshelf) {
	if (!$xml.configuration.services)
	{
		$servicesElement = $xml.CreateElement("services")
		$topshelfServiceElement = $xml.CreateElement("TopshelfService")
		$servicesElement.AppendChild($topshelfServiceElement)
		$xml.configuration.AppendChild($servicesElement)
		$xml.Save($xmlPath)
	}
}

if($isWindowsService) {
	if (!$xml.configuration.services)
	{
		$servicesElement = $xml.CreateElement("services")
		$windowsServiceElement = $xml.CreateElement("WindowsService")
		$servicesElement.AppendChild($windowsServiceElement)
		$xml.configuration.AppendChild($servicesElement)
		$xml.Save($xmlPath)
	}
}







$legacyUpdateConfiguration = $project.ProjectItems | ?{ $_.Name.Equals("UpdateConfiguration.ps1") }
 
if($legacyUpdateConfiguration) {
	$legacyUpdateConfigurationContent = gc ($legacyUpdateConfiguration.Properties.Item("FullPath").Value)
	$newUpdateConfigurationPath = $project.ProjectItems.Item("Deployment").ProjectItems.Item("UpdateConfiguration.ps1").Properties.Item("FullPath").Value
	
	$newUpdateConfiguration = gc $newUpdateConfigurationPath
	
	# Lets compare to the nuget package version to see whether we should merge files
	$packageUpdateConfiguration = gc "$installPath\templates\UpdateConfiguration.ps1"
	
	# Only append legacy UpdateConfiguration if we haven't modified UpdateConfiguration.ps1 already
	if($(Compare $packageUpdateConfiguration $newUpdateConfiguration) -eq $null) {
		$newUpdateConfiguration += $legacyUpdateConfigurationContent
		Set-Content $newUpdateConfigurationPath -Value $newUpdateConfiguration
	}
}