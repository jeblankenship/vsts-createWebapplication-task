[CmdletBinding()]
param(
    [string]$server,
    [string]$webSiteName,
    [string]$webAppName,
    [string]$appPoolName,
    [string]$filePath
)

Import-Module "Microsoft.TeamFoundation.DistributedTask.Task.Internal"
Import-Module "Microsoft.TeamFoundation.DistributedTask.Task.Common"

Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
Write-Verbose "Parameter Values"
$PSBoundParameters.Keys | % { Write-HOST "  ${_} = $($PSBoundParameters[$_])" }

$command = {
    param(
        [string]$webSiteName,
        [string]$webAppName,
        [string]$appPoolName,
        [string]$filePath
    )
    Import-Module WebAdministration
    Write-Host "Starting Create Web Application Task"
    $appPoolPath = "IIS:\AppPools\$AppPoolName"
    Write-Host "Checking for application pool: '$appPoolName'"
    if(-Not (Test-Path $appPoolPath)) {
        Write-Host "Creating Application Pool with default settings"
        $appPool = New-Item –Path $appPoolPath
        $appPool.managedRuntimeVersion = "v4.0"
        $appPool.managedPipeLineMode = "Integrated"
        Write-Host "Application Pool created."
    } else {
        Write-Host "Application Pool exist"
    }
    $webAppPath = "IIS:\Sites\$webSiteName\$webAppName"
    Write-Host "Checking for web application '$webAppName' in site '$webSiteName'"
    if (Test-Path $webAppPath) { 
        Write-Host "$webSiteName exists. Skipping Task" 
    } else {
        Write-Host "Creating web application '$webAppName' in site '$webSiteName'"
        New-WebApplication -Name $webAppName -ApplicationPool $appPoolName  -Force -PhysicalPath $filePath  -Site $webSiteName 
        Write-Host "Created web application '$webAppName' in site '$webSiteName'"
    }
    $currentAppPool = (Get-Item $webAppPath | Select applicationPool).applicationPool
    Write-Host "Current Application Pool: $currentAppPool"
    if ($appPoolName -ne $currentAppPool){
        write-host "Changing Application Pool to $appPoolName"
        Set-ItemProperty $webAppPath -name applicationPool  -value $appPoolName -force
        $currentAppPool = (Get-Item $webAppPath | Select applicationPool).applicationPool
        Write-Host "Current Application Pool: $currentAppPool"
    }
    Write-Host "Create WebApplication Task Completed."
}

Invoke-Command -ComputerName $server $command -ArgumentList $webSiteName,$webAppName,$appPoolName,$filePath