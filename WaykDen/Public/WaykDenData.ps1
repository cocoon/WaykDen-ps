
. "$PSScriptRoot/../Private/DockerHelper.ps1"

function Backup-WaykDenData
{
    param(
        [string] $Path,
        [string] $OutputPath
    )

    if ([string]::IsNullOrEmpty($Path)) {
        $Path = Get-Location
    }

    $config = Get-WaykDenConfig -Path:$Path
    Expand-WaykDenConfig -Config $config

    $Platform = $config.DockerPlatform
    $Services = Get-WaykDenService -Path:$Path -Config $config

    $Service = ($Services | Where-Object { $_.ContainerName -Like '*mongo' })[0]
    $container = $Service.ContainerName

    if ($Platform -eq "linux") {
        $PathSeparator = "/"
        $TempPath = "/tmp"
    } else {
        $PathSeparator = "\"
        $TempPath = "C:\temp"
    }

    $BackupFileName = "den-mongo.tgz"
    $BackupPath = @($TempPath, $BackupFileName) -Join $PathSeparator

    docker @('exec', $container, 'mongodump', '--gzip', "--archive=${BackupPath}")
    docker @('cp', "$container`:$BackupPath", $BackupFileName)
}

function Restore-WaykDenData
{
    param(
        [string] $Path,
        [string] $InputPath
    )

    if ([string]::IsNullOrEmpty($Path)) {
        $Path = Get-Location
    }

    $config = Get-WaykDenConfig -Path:$Path
    Expand-WaykDenConfig -Config $config

    $Platform = $config.DockerPlatform
    $Services = Get-WaykDenService -Path:$Path -Config $config

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
    $BackupPath = @($TempPath, $BackupFileName) -Join $PathSeparator

    if (-Not (Get-ContainerIsRunning -Name $ContainerName)) {
        Start-DockerService $Service
    }

    docker @('cp', $BackupFileName, "$ContainerName`:$BackupPath")
    docker @('exec', $ContainerName, 'mongorestore', '--drop', '--gzip', "--archive=${BackupPath}")
}

Export-ModuleMember -Function Backup-WaykDenData, Restore-WaykDenData
