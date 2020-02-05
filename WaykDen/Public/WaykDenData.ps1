
. "$PSScriptRoot/../Private/DockerHelper.ps1"

function Backup-WaykDenData
{
    [CmdletBinding()]
    param(
        [string] $ConfigPath,
        [string] $OutputPath
    )

    $ConfigPath = Find-WaykDenConfig -ConfigPath:$ConfigPath

    $config = Get-WaykDenConfig -ConfigPath:$ConfigPath
    Expand-WaykDenConfig -Config $config

    $Platform = $config.DockerPlatform
    $Services = Get-WaykDenService -ConfigPath:$ConfigPath -Config $config

    $Service = ($Services | Where-Object { $_.ContainerName -Like '*mongo' })[0]
    $container = $Service.ContainerName

    if ($Platform -eq "linux") {
        $PathSeparator = "/"
        $TempPath = "/tmp"
    } else {
        $PathSeparator = "\"
        $TempPath = "C:\temp"
    }

    if (-Not $OutputPath) {
        $OutputPath = Get-Location
    }

    $BackupFileName = "den-mongo.tgz"
    if (($OutputPath -match ".tgz") -or ($OutputPath -match ".tar.gz")) {
        $BackupFileName = Split-Path -Path $OutputPath -Leaf
    } else {
        $OutputPath = Join-Path $OutputPath $BackupFileName
    }

    $TempBackupPath = @($TempPath, $BackupFileName) -Join $PathSeparator

    # make sure parent output directory exists
    New-Item -Path $(Split-Path -Path $OutputPath) -ItemType "Directory" -Force | Out-Null

    docker @('exec', $container, 'mongodump', '--gzip', "--archive=${TempBackupPath}")
    docker @('cp', "$container`:$TempBackupPath", $OutputPath)
}

function Restore-WaykDenData
{
    [CmdletBinding()]
    param(
        [string] $ConfigPath,
        [string] $InputPath
    )

    $ConfigPath = Find-WaykDenConfig -ConfigPath:$ConfigPath

    $config = Get-WaykDenConfig -ConfigPath:$ConfigPath
    Expand-WaykDenConfig -Config $config

    $Platform = $config.DockerPlatform
    $Services = Get-WaykDenService -ConfigPath:$ConfigPath -Config $config

    $Service = ($Services | Where-Object { $_.ContainerName -Like '*mongo' })[0]
    $ContainerName = $Service.ContainerName

    if ($Platform -eq "linux") {
        $PathSeparator = "/"
        $TempPath = "/tmp"
    } else {
        $PathSeparator = "\"
        $TempPath = "C:\temp"
    }

    $BackupFileName = "den-mongo.tgz"

    if (($InputPath -match ".tgz") -or ($InputPath -match ".tar.gz")) {
        $BackupFileName = Split-Path -Path $InputPath -Leaf
    } else {
        $InputPath = Join-Path $InputPath $BackupFileName
    }

    $TempBackupPath = @($TempPath, $BackupFileName) -Join $PathSeparator

    if (-Not (Get-ContainerIsRunning -Name $ContainerName)) {
        Start-DockerService $Service
    }

    if (-Not (Test-Path -Path $InputPath -PathType 'Leaf')) {
        throw "$InputPath does not exist"
    }

    docker @('cp', $InputPath, "$ContainerName`:$TempBackupPath")
    docker @('exec', $ContainerName, 'mongorestore', '--drop', '--gzip', "--archive=${TempBackupPath}")
}

Export-ModuleMember -Function Backup-WaykDenData, Restore-WaykDenData
