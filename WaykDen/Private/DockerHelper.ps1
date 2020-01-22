
function Get-ContainerExists
{
    param(
        [string] $Name
    )

    $exists = $(docker ps -aqf "name=$Name")
    return ![string]::IsNullOrEmpty($exists)
}

function Get-ContainerIsRunning
{
    param(
        [string] $Name
    )

    $running = $(docker inspect -f '{{.State.Running}}' $Name)
    return $running -Match 'true'
}

function Get-ContainerIsHealthy
{
    param(
        [string] $Name
    )

    $healthy = $(docker inspect -f '{{.State.Health.Status}}' $Name)
    return $healthy -Match 'healthy'
}

function Wait-ContainerHealthy
{
    param(
        [string] $Name
    )

    $seconds = 0
    $timeout = 15
    $interval = 1

    while (($seconds -lt $timeout) -And !(Get-ContainerIsHealthy -Name:$Name) -And (Get-ContainerIsRunning -Name:$Name)) {
        Start-Sleep -Seconds $interval
        $seconds += $interval
    }

    return (Get-ContainerIsHealthy -Name:$Name)
}
