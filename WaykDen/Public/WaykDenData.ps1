
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
    
    $backup_file = "den-backup.tgz"
    $backup_tgz = "/tmp/$backup_file"

    docker @('exec', $container, 'mongodump', '--gzip', "--archive=${backup_tgz}")
    docker @('cp', "$container`:$backup_tgz", "den-backup.tgz")
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
    $container = $Service.ContainerName

    $backup_file = "den-backup.tgz"
    $backup_tgz = "/tmp/$backup_file"

    docker @('cp', "den-backup.tgz", "$container`:$backup_tgz")
    docker @('exec', $container, 'mongorestore', '--drop', '--gzip', "--archive=${backup_tgz}")
}

Export-ModuleMember -Function Backup-WaykDenData, Restore-WaykDenData
