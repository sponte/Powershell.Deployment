if (!(Test-Path .\..\nuget)) {
    New-Item -Path .\..\nuget -Type directory
    }
.\NuGet.exe pack Powershell.Deployment.nuspec -OutputDirectory .\..\nuget
