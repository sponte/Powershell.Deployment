function Install-FilePermissions {
    param( 
		[Parameter(Mandatory = $true)]       
		[string] 
		$rootPath,
		[Parameter(Mandatory = $true)]
		[System.XML.XMLDocument] 
		$configuration
	)
	
	foreach($filePermission in @($configuration.configuration.filePermissions.filePermission)) {
		if(!$filePermission) { continue }
		Install-FilePermission -rootPath $rootPath -filePermissionConfig $filePermission
	}
}

function Uninstall-FilePermissions {
    param(        
 		[Parameter(Mandatory = $true)]       
		[string] 
		$rootPath,
		[Parameter(Mandatory = $true)]
		[System.XML.XMLDocument] 
		$configuration
	)
	
	foreach($filePermission in @($configuration.configuration.filePermissions.filePermission)) {
		if(!$filePermission) { continue }
		Uninstall-FilePermission $rootPath $filePermission
	}
}

# Methods

function Uninstall-FilePermission {
	param(
 		[Parameter(Mandatory = $true)]       
		[string] 
		$rootPath,
	    [Parameter(Mandatory = $true)]
		[System.XML.XMLElement]
		$filePermissionConfig
	)

	$name = $filePermissionConfig.name
	$path = $filePermissionConfig.path
	if($path.StartsWith(".")) {
		$path = (Join-Path $rootPath $path.SubString(1, $path.Length - 1)).ToString()
	}

	$removeOnUninstall= $filePermissionConfig.removeOnUninstall -eq $true

	if ($removeOnUninstall) {
		foreach($fileSystemRight in @($filePermission.fileSystemRights.fileSystemRight)) {
			$acl=get-acl $path

			$username = Format-AccountName $fileSystemRight.Username
		
			$InheritanceFlags = @()
			$containerInherit = $fileSystemRight.containerInherit -eq $true
			$objectInherit = $fileSystemRight.objectInherit -eq $true

			if ($containerInherit) {
				$InheritanceFlags+= "ContainerInherit"
			}

			if ($objectInherit) {
				$InheritanceFlags+= "ObjectInherit"
			}

			if (!$objectInherit -and !$objectInherit) {
				$InheritanceFlags+= "None"
			}

			$InheritanceFlagsText  = $InheritanceFlags -join ','

			$propagationFlags = $fileSystemRight.propagationType

			$accessControlType = $fileSystemRight.AccessControlType
		
			$AppendData = $fileSystemRight.AppendData -eq $true
			if ($AppendData)
			{
				$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"AppendData", $InheritanceFlagsText , $propagationFlags, $accessControlType)
				$acl.RemoveAccessRule($rule)
			}
			$ChangePermissions = $fileSystemRight.ChangePermissions -eq $true
			if ($ChangePermissions)
			{
				$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"ChangePermissions", $InheritanceFlagsText , $propagationFlags, $accessControlType)
				$acl.RemoveAccessRule($rule)
			}
			$CreateDirectories = $fileSystemRight.CreateDirectories -eq $true
			if ($CreateDirectories)
			{
				$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"CreateDirectories", $InheritanceFlagsText , $propagationFlags, $accessControlType)
				$acl.RemoveAccessRule($rule)
			}
			$CreateFiles = $fileSystemRight.CreateFiles -eq $true
			if ($CreateFiles)
			{
				$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"CreateFiles", $InheritanceFlagsText , $propagationFlags, $accessControlType)
				$acl.RemoveAccessRule($rule)
			}
			$Delete = $fileSystemRight.Delete -eq $true
			if ($Delete)
			{
				$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"Delete", $InheritanceFlagsText , $propagationFlags, $accessControlType)
				$acl.RemoveAccessRule($rule)
			}
			$DeleteSubdirectoriesAndFiles = $fileSystemRight.DeleteSubdirectoriesAndFiles -eq $true
			if ($DeleteSubdirectoriesAndFiles)
			{
				$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"DeleteSubdirectoriesAndFiles", $InheritanceFlagsText , $propagationFlags, $accessControlType)
				$acl.RemoveAccessRule($rule)
			}
			$ExecuteFile = $fileSystemRight.ExecuteFile -eq $true
			if ($ExecuteFile)
			{
				$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"ExecuteFile", $InheritanceFlagsText , $propagationFlags, $accessControlType)
				$acl.RemoveAccessRule($rule)
			}
			$FullControl = $fileSystemRight.FullControl -eq $true
			if ($FullControl)
			{
				$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"FullControl", $InheritanceFlagsText , $propagationFlags, $accessControlType)
				$acl.RemoveAccessRule($rule)
			}
			$ListDirectory = $fileSystemRight.ListDirectory -eq $true
			if ($ListDirectory)
			{
				$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"ListDirectory", $InheritanceFlagsText , $propagationFlags, $accessControlType)
				$acl.RemoveAccessRule($rule)
			}
			$Modify = $fileSystemRight.Modify -eq $true
			if ($Modify)
			{
				$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"Modify", $InheritanceFlagsText , $propagationFlags, $accessControlType)
				$acl.RemoveAccessRule($rule)
			}
			$Read = $fileSystemRight.Read -eq $true
			if ($Read)
			{
				$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"Read", $InheritanceFlagsText , $propagationFlags, $accessControlType)
				$acl.RemoveAccessRule($rule)
			}
			$ReadAndExecute = $fileSystemRight.ReadAndExecute -eq $true
			if ($ReadAndExecute)
			{
				$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"ReadAndExecute", $InheritanceFlagsText , $propagationFlags, $accessControlType)
				$acl.RemoveAccessRule($rule)
			}
			$ReadAttributes = $fileSystemRight.ReadAttributes -eq $true
			if ($ReadAttributes)
			{
				$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"ReadAttributes", $InheritanceFlagsText , $propagationFlags, $accessControlType)
				$acl.RemoveAccessRule($rule)
			}
			$ReadData = $fileSystemRight.ReadData -eq $true
			if ($ReadData)
			{
				$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"ReadData", $InheritanceFlagsText , $propagationFlags, $accessControlType)
				$acl.RemoveAccessRule($rule)
			}
			$ReadExtendedAttributes = $fileSystemRight.ReadExtendedAttributes -eq $true
			if ($ReadExtendedAttributes)
			{
				$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"ReadExtendedAttributes", $InheritanceFlagsText , $propagationFlags, $accessControlType)
				$acl.RemoveAccessRule($rule)
			}
			$ReadPermissions = $fileSystemRight.ReadPermissions -eq $true
			if ($ReadPermissions)
			{
				$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"ReadPermissions", $InheritanceFlagsText , $propagationFlags, $accessControlType)
				$acl.RemoveAccessRule($rule)
			}
			$Synchronize = $fileSystemRight.Synchronize -eq $true
			if ($Synchronize)
			{
				$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"Synchronize", $InheritanceFlagsText , $propagationFlags, $accessControlType)
				$acl.RemoveAccessRule($rule)
			}
			$TakeOwnership = $fileSystemRight.TakeOwnership -eq $true
			if ($TakeOwnership)
			{
				$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"TakeOwnership", $InheritanceFlagsText , $propagationFlags, $accessControlType)
				$acl.RemoveAccessRule($rule)
			}
			$Traverse = $fileSystemRight.Traverse -eq $true
			if ($Traverse)
			{
				$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"Traverse", $InheritanceFlagsText , $propagationFlags, $accessControlType)
				$acl.RemoveAccessRule($rule)
			}
			$Write = $fileSystemRight.Write -eq $true
			if ($Write)
			{
				$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"Write", $InheritanceFlagsText , $propagationFlags, $accessControlType)
				$acl.RemoveAccessRule($rule)
			}
			$WriteAttributes = $fileSystemRight.WriteAttributes -eq $true
			if ($WriteAttributes)
			{
				$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"WriteAttributes", $InheritanceFlagsText , $propagationFlags, $accessControlType)
				$acl.RemoveAccessRule($rule)
			}
			$WriteData = $fileSystemRight.WriteData -eq $true
			if ($WriteData)
			{
				$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"WriteData", $InheritanceFlagsText , $propagationFlags, $accessControlType)
				$acl.RemoveAccessRule($rule)
			}
			$WriteExtendedAttributes = $fileSystemRight.WriteExtendedAttributes -eq $true
			if ($WriteExtendedAttributes)
			{
				$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"WriteExtendedAttributes", $InheritanceFlagsText , $propagationFlags, $accessControlType)
				$acl.RemoveAccessRule($rule)
			}

			set-acl $path $acl
		}
	}
}

function Install-FilePermission {
	param(
		[Parameter(Mandatory = $true)]
		[string]
		$rootPath,
		[Parameter(Mandatory = $true)]
		[System.XML.XMLElement]
		$filePermissionConfig
	)
	
	#UnInstall-FilePermission $rootPath $filePermissionConfig

	$name = $filePermissionConfig.name
	$path = $filePermissionConfig.path
	if($path.StartsWith(".")) {
		$path = (Join-Path $rootPath $path.SubString(1, $path.Length - 1)).ToString()
	}

	$removeOnUninstall= $filePermissionConfig.removeOnUninstall -eq $true

	foreach($fileSystemRight in @($filePermission.fileSystemRights.fileSystemRight)) {	

		$acl=get-acl $path

		$username = Format-AccountName $fileSystemRight.Username
		
		$InheritanceFlags = @()
		$containerInherit = $fileSystemRight.containerInherit -eq $true
		$objectInherit = $fileSystemRight.objectInherit -eq $true

		if ($containerInherit) {
			$InheritanceFlags+= "ContainerInherit"
		}

		if ($objectInherit) {
			$InheritanceFlags+= "ObjectInherit"
		}

		if (!$objectInherit -and !$objectInherit) {
			$InheritanceFlags+= "None"
		}

		$InheritanceFlagsText  = $InheritanceFlags -join ','

		$propagationFlags = $fileSystemRight.propagationType

		$accessControlType = $fileSystemRight.AccessControlType
		
		$AppendData = $fileSystemRight.AppendData -eq $true
		if ($AppendData)
		{
			$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"AppendData", $InheritanceFlagsText , $propagationFlags, $accessControlType)
			$acl.AddAccessRule($rule)
		}
		$ChangePermissions = $fileSystemRight.ChangePermissions -eq $true
		if ($ChangePermissions)
		{
			$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"ChangePermissions", $InheritanceFlagsText , $propagationFlags, $accessControlType)
			$acl.AddAccessRule($rule)
		}
		$CreateDirectories = $fileSystemRight.CreateDirectories -eq $true
		if ($CreateDirectories)
		{
			$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"CreateDirectories", $InheritanceFlagsText , $propagationFlags, $accessControlType)
			$acl.AddAccessRule($rule)
		}
		$CreateFiles = $fileSystemRight.CreateFiles -eq $true
		if ($CreateFiles)
		{
			$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"CreateFiles", $InheritanceFlagsText , $propagationFlags, $accessControlType)
			$acl.AddAccessRule($rule)
		}
		$Delete = $fileSystemRight.Delete -eq $true
		if ($Delete)
		{
			$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"Delete", $InheritanceFlagsText , $propagationFlags, $accessControlType)
			$acl.AddAccessRule($rule)
		}
		$DeleteSubdirectoriesAndFiles = $fileSystemRight.DeleteSubdirectoriesAndFiles -eq $true
		if ($DeleteSubdirectoriesAndFiles)
		{
			$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"DeleteSubdirectoriesAndFiles", $InheritanceFlagsText , $propagationFlags, $accessControlType)
			$acl.AddAccessRule($rule)
		}
		$ExecuteFile = $fileSystemRight.ExecuteFile -eq $true
		if ($ExecuteFile)
		{
			$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"ExecuteFile", $InheritanceFlagsText , $propagationFlags, $accessControlType)
			$acl.AddAccessRule($rule)
		}
		$FullControl = $fileSystemRight.FullControl -eq $true
		if ($FullControl)
		{
			$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"FullControl", $InheritanceFlagsText , $propagationFlags, $accessControlType)
			$acl.AddAccessRule($rule)
		}
		$ListDirectory = $fileSystemRight.ListDirectory -eq $true
		if ($ListDirectory)
		{
			$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"ListDirectory", $InheritanceFlagsText , $propagationFlags, $accessControlType)
			$acl.AddAccessRule($rule)
		}
		$Modify = $fileSystemRight.Modify -eq $true
		if ($Modify)
		{
			Write-Warning "New-Object System.Security.AccessControl.FileSystemAccessRule('$username','Modify', '$InheritanceFlagsText', '$propagationFlags', '$accessControlType')"
			$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"Modify", $InheritanceFlagsText, $propagationFlags, $accessControlType)
			
			Write-Warning "add access rule"
			$acl.AddAccessRule($rule)
		}
		$Read = $fileSystemRight.Read -eq $true
		if ($Read)
		{
			$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"Read", $InheritanceFlagsText , $propagationFlags, $accessControlType)
			$acl.AddAccessRule($rule)
		}
		$ReadAndExecute = $fileSystemRight.ReadAndExecute -eq $true
		if ($ReadAndExecute)
		{
			$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"ReadAndExecute", $InheritanceFlagsText , $propagationFlags, $accessControlType)
			$acl.AddAccessRule($rule)
		}
		$ReadAttributes = $fileSystemRight.ReadAttributes -eq $true
		if ($ReadAttributes)
		{
			$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"ReadAttributes", $InheritanceFlagsText , $propagationFlags, $accessControlType)
			$acl.AddAccessRule($rule)
		}
		$ReadData = $fileSystemRight.ReadData -eq $true
		if ($ReadData)
		{
			$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"ReadData", $InheritanceFlagsText , $propagationFlags, $accessControlType)
			$acl.AddAccessRule($rule)
		}
		$ReadExtendedAttributes = $fileSystemRight.ReadExtendedAttributes -eq $true
		if ($ReadExtendedAttributes)
		{
			$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"ReadExtendedAttributes", $InheritanceFlagsText , $propagationFlags, $accessControlType)
			$acl.AddAccessRule($rule)
		}
		$ReadPermissions = $fileSystemRight.ReadPermissions -eq $true
		if ($ReadPermissions)
		{
			$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"ReadPermissions", $InheritanceFlagsText , $propagationFlags, $accessControlType)
			$acl.AddAccessRule($rule)
		}
		$Synchronize = $fileSystemRight.Synchronize -eq $true
		if ($Synchronize)
		{
			$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"Synchronize", $InheritanceFlagsText , $propagationFlags, $accessControlType)
			$acl.AddAccessRule($rule)
		}
		$TakeOwnership = $fileSystemRight.TakeOwnership -eq $true
		if ($TakeOwnership)
		{
			$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"TakeOwnership", $InheritanceFlagsText , $propagationFlags, $accessControlType)
			$acl.AddAccessRule($rule)
		}
		$Traverse = $fileSystemRight.Traverse -eq $true
		if ($Traverse)
		{
			$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"Traverse", $InheritanceFlagsText , $propagationFlags, $accessControlType)
			$acl.AddAccessRule($rule)
		}
		$Write = $fileSystemRight.Write -eq $true
		if ($Write)
		{
			$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"Write", $InheritanceFlagsText , $propagationFlags, $accessControlType)
			$acl.AddAccessRule($rule)
		}
		$WriteAttributes = $fileSystemRight.WriteAttributes -eq $true
		if ($WriteAttributes)
		{
			$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"WriteAttributes", $InheritanceFlagsText , $propagationFlags, $accessControlType)
			$acl.AddAccessRule($rule)
		}
		$WriteData = $fileSystemRight.WriteData -eq $true
		if ($WriteData)
		{
			$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"WriteData", $InheritanceFlagsText , $propagationFlags, $accessControlType)
			$acl.AddAccessRule($rule)
		}
		$WriteExtendedAttributes = $fileSystemRight.WriteExtendedAttributes -eq $true
		if ($WriteExtendedAttributes)
		{
			$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,"WriteExtendedAttributes", $InheritanceFlagsText , $propagationFlags, $accessControlType)
			$acl.AddAccessRule($rule)
		}

		set-acl $path $acl
	}
}
