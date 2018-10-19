#Requires -Modules Microsoft.PowerShell.Management, WebAdministration

function New-WebApplicationConcurrentSafe {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String] $ApplicationPool,
        [Parameter(Mandatory)]
        [String] $Name,
        [Parameter(Mandatory)]
        [String] $PhysicalPath,
        [Parameter(Mandatory)]
        [String] $Site
    )
    Process {
        Invoke-MutexProtectedIISCommand { 
            New-WebApplication `
                    -ApplicationPool $ApplicationPool `
                    -Name $Name `
                    -PhysicalPath $PhysicalPath `
                    -Site $Site `
                    -Force
        }
    }
}

function Remove-WebApplicationConcurrentSafe {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String] $Name,
        [Parameter(Mandatory)]
        [String] $Site
    )
    Process {
        Invoke-MutexProtectedIISCommand { Remove-WebApplication -Name $Name -Site $Site }
    }
}

function New-WebAppPoolConcurrentSafe {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String] $Name
    )
    Invoke-MutexProtectedIISCommand { New-WebAppPool $Name }
}

function Remove-WebAppPoolConcurrentSafe {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String] $Name
    )
    Invoke-MutexProtectedIISCommand { Remove-WebAppPool $Name }
}

function Remove-WebsiteConcurrentSafe {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String] $Name
    )
    Invoke-MutexProtectedIISCommand { Remove-Website $Name }
}

function Stop-WebAppPoolConcurrentSafe {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String] $Name
    )
    Invoke-MutexProtectedIISCommand { Stop-WebAppPool $Name }
}

function Set-ItemPropertyConcurrentSafe {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String] $Path,
        [Parameter(Mandatory)]
        [String] $Name,
        [Parameter(Mandatory)]
        [String] $Value
    )
    Invoke-MutexProtectedIISCommand { Set-ItemProperty -Path $Path -Name $Name -Value $Value }
}

function New-WebVirtualDirectoryConcurrentSafe {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String] $Name,
        [Parameter(Mandatory)]
        [String] $PhysicalPath,
        [Parameter(Mandatory)]
        [String] $Site
    )
    Process {
        Invoke-MutexProtectedIISCommand { 
            New-WebVirtualDirectory `
                -Name $Name `
                -PhysicalPath $PhysicalPath `
                -Site $Site `
                -Force
        }
    }
}

function Set-ItemConcurrentSafe {
    [CmdletBinding()]
    param (
        [object] $Value
    )
    Process {
        Invoke-MutexProtectedIISCommand { $Value | Set-Item }
    }
}

function Invoke-MutexProtectedIISCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ScriptBlock] $command
    )
    Process {
        [object] $resultOfCommand = $null
        $mutex = New-Object System.Threading.Mutex($false, 'Powershell.Deployment-IIS');
        try {
            if ($mutex.WaitOne(2000)) {
                $resultOfCommand = & $command
            }
        } catch [System.Threading.AbandonedMutexException] {
            $_.Exception.Mutex.ReleaseMutex()
            throw
        } finally {
            $mutex.ReleaseMutex()
        }

        return $resultOfCommand
    }
}
