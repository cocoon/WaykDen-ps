
. "$PSScriptRoot/../Private/PlatformHelper.ps1"

function Get-WaykDenImage
{
    $images = if (!(Get-IsWindows)) {
        [ordered]@{ # Linux containers
            "den-mongo" = "library/mongo:4.1-bionic";
            "den-lucid" = "devolutions/den-lucid:3.6.5-buster";
            "den-picky" = "devolutions/picky:4.2.1-buster";
            "den-server" = "devolutions/den-server:1.9.0-buster";
            "den-traefik" = "library/traefik:1.7";
        }
    } else {
        [ordered]@{ # Windows containers
            "den-mongo" = "devolutions/mongo:4.0.12-windowsservercore-ltsc2019";
            "den-lucid" = "devolutions/den-lucid:3.6.5-servercore-ltsc2019";
            "den-picky" = "devolutions/picky:4.2.1-servercore-ltsc2019";
            "den-server" = "devolutions/den-server:1.9.0-servercore-ltsc2019";
            "den-traefik" = "sixeyed/traefik:v1.7.8-windowsservercore-ltsc2019";
        }
    }

    return $images
}

function Get-WaykDenService
{
    param(
        [string] $Path,
        [string] $DenNetwork,
        [string] $MongoVolume
    )

    $config = Get-WaykDenConfig -Path:$Path

    $images = Get-WaykDenImage

    $Realm = $config.Realm
    $ExternalUrl = $config.ExternalUrl

    if ([string]::IsNullOrEmpty($DenNetwork)) {
        $DenNetwork = "den-network"
    }

    $MongoUrl = $config.MongoUrl

    if ([string]::IsNullOrEmpty($MongoUrl)) {
        $MongoUrl = "mongodb://den-mongo:27017"
    }

    if ([string]::IsNullOrEmpty($MongoVolume)) {
        $MongoVolume = "den-mongodata"
    }

    $TraefikPort = $config.WaykDenPort

    if ([string]::IsNullOrEmpty($TraefikPort)) {
        $TraefikPort = 4000
    }

    $LucidAdminSecret = "Hgte1n3RIS" # generate
    $LucidAdminUsername = "k8QyMU61rpfFJRbK" # generate
    $LucidApiKey = "Jui2NzSxBE3GSKx2VsGMAUTj9MB85iAT" # generate
    $PickyApiKey = "Legv4-AHWX9BSsJ8080vl-T2lDcV9Aj5" # generate
    $DenApiKey = "PHyJaFk-OkmsfBZEZ-LaaoNwtlSc8HxB" # generate

    # den-mongo service
    $DenMongo = [DockerService]::new()
    $DenMongo.ContainerName = 'den-mongo'
    $DenMongo.Image = $images[$DenMongo.ContainerName]
    $DenMongo.Networks += $DenNetwork
    $DenMongo.Volumes = @("$MongoVolume`:/data/db")

    # den-picky service
    $DenPicky = [DockerService]::new()
    $DenPicky.ContainerName = 'den-picky'
    $DenPicky.Image = $images[$DenPicky.ContainerName]
    $DenPicky.DependsOn = @("den-mongo")
    $DenPicky.Networks += $DenNetwork
    $DenPicky.Environment = [ordered]@{
        "PICKY_REALM" = $Realm;
        "PICKY_API_KEY" = $PickyApiKey;
        "PICKY_DATABASE_URL" = $MongoUrl;
    }

    # den-lucid service
    $DenLucid = [DockerService]::new()
    $DenLucid.ContainerName = 'den-lucid'
    $DenLucid.Image = $images[$DenLucid.ContainerName]
    $DenLucid.DependsOn = @("den-mongo")
    $DenLucid.Networks += $DenNetwork
    $DenLucid.Environment = [ordered]@{
        "LUCID_ADMIN__SECRET" = $LucidAdminSecret;
        "LUCID_ADMIN__USERNAME" = $LucidAdminUsername;
        "LUCID_AUTHENTICATION__KEY" = $LucidApiKey;
        "LUCID_DATABASE__URL" = $MongoUrl;
        "LUCID_TOKEN__ISSUER" = "$ExternalUrl/lucid";
        "LUCID_ACCOUNT__APIKEY" = $DenApiKey;
        "LUCID_ACCOUNT__LOGIN_URL" = "http://den-server:10255/account/login";
        "LUCID_ACCOUNT__REFRESH_USER_URL" = "http://den-server:10255/account/refresh";
        "LUCID_ACCOUNT__FORGOT_PASSWORD_URL" = "http://den-server:10255/account/forgot";
        "LUCID_ACCOUNT__SEND_ACTIVATION_EMAIL_URL" = "http://den-server:10255/account/activation";
    }
    $DenLucid.Healthcheck = [DockerHealthcheck]::new("curl -sS http://den-lucid:4242/health")

    # den-server service
    $DenServer = [DockerService]::new()
    $DenServer.ContainerName = 'den-server'
    $DenServer.Image = $images[$DenServer.ContainerName]
    $DenServer.DependsOn = @("den-mongo", 'traefik')
    $DenServer.Networks += $DenNetwork
    $DenServer.Environment = [ordered]@{
        "PICKY_REALM" = $Realm;
        "PICKY_URL" = "http://den-picky:12345";
        "PICKY_APIKEY" = $PickyApiKey;
        "AUDIT_TRAILS" = "true";
        "LUCID_AUTHENTICATION_KEY" = $PickyApiKey;
        "DEN_ROUTER_EXTERNAL_URL" = "wss://$ExternalUrl/cow";
        "LUCID_INTERNAL_URL" = "http://den-lucid:4242";
        "LUCID_EXTERNAL_URL" = "$ExternalUrl/lucid";
        "DEN_LOGIN_REQUIRED" = "false";
        "DEN_PRIVATE_KEY_FILE" = "/etc/den-server/den-server.key";
        "DEN_PUBLIC_KEY_FILE" = "/etc/den-server/den-router.key";
        "JET_SERVER_URL" = "api.jet-relay.net:8080";
        "JET_RELAY_URL" = $config.JetRelayUrl;
        "DEN_API_KEY" = $DenApiKey;
    }
    $DenServer.Volumes = @("den-server:/etc/den-server:ro")
    $DenServer.Command = "--db_url $MongoUrl -m onprem -l trace"
    $DenServer.Healthcheck = [DockerHealthcheck]::new("curl -sS http://den-server:10255/health")

    # den-traefik service
    $DenTraefik = [DockerService]::new()
    $DenTraefik.ContainerName = 'den-traefik'
    $DenTraefik.Image = $images[$DenTraefik.ContainerName]
    $DenTraefik.Networks += $DenNetwork
    $DenTraefik.Volumes = @("traefik:/etc/traefik")
    $DenTraefik.Command = "--file --configFile=/etc/traefik/traefik.toml"
    $DenTraefik.Ports = @("4000:$TraefikPort")

    $Services = @($DenMongo, $DenPicky, $DenLucid, $DenServer, $DenTraefik)
    return $Services
}

function New-DockerNetwork
{
    param(
        [Parameter(Mandatory=$true)]
        [string] $Name,

        [switch] $Force
    )

    $output = $(docker network ls -qf "name=$Name")

    if ([string]::IsNullOrEmpty($output)) {
        docker network create $Name
    }
}

function New-DockerVolume
{
    param(
        [Parameter(Mandatory=$true)]
        [string] $Name,

        [switch] $Force
    )

    $output = $(docker volume ls -qf "name=$Name")

    if ([string]::IsNullOrEmpty($output)) {
        docker volume create $Name
    }
}

class DockerHealthcheck
{
    [string] $Test
    [string] $Interval
    [string] $Timeout
    [string] $Retries
    [string] $StartPeriod

    DockerHealthcheck([string] $Test) {
        $this.Test = $Test
        $this.Interval = "5s"
        $this.Timeout = "2s"
        $this.Retries = "5"
        $this.StartPeriod = "1s"
    }
}

class DockerService
{
    [string] $Image
    [string] $ContainerName
    [string[]] $DependsOn
    [string[]] $Networks
    [Hashtable] $Environment
    [string[]] $Volumes
    [string] $Command
    [string[]] $Ports
    [DockerHealthcheck] $Healthcheck
}

function Get-DockerRunCommand
{
    [OutputType('string[]')]
    param(
        [DockerService] $Service
    )

    $cmd = @('docker', 'run', '-d')

    if ($Service.Networks) {
        foreach ($Network in $Service.Networks) {
            $cmd += "--network=$Network"
        }
    }

    if ($Service.Environment) {
        $Service.Environment.GetEnumerator() | foreach {
            $key = $_.Key
            $val = $_.Value
            $cmd += @("-e", "$key=$val")
        }
    }

    if ($Service.Volumes) {
        foreach ($Volume in $Service.Volumes) {
            $cmd += @("-v", $Volume)
        }
    }

    if ($Service.Ports) {
        foreach ($Port in $Service.Ports) {
            $cmd += @("-p", $Port)
        }
    }

    if ($Service.Healthcheck) {
        $Healthcheck = $Service.Healthcheck
        if (![string]::IsNullOrEmpty($Healthcheck.Interval)) {
            $cmd += "--health-interval=" + $Healthcheck.Interval
        }
        if (![string]::IsNullOrEmpty($Healthcheck.Timeout)) {
            $cmd += "--health-timeout=" + $Healthcheck.Timeout
        }
        if (![string]::IsNullOrEmpty($Healthcheck.Retries)) {
            $cmd += "--health-retries=" + $Healthcheck.Retries
        }
        if (![string]::IsNullOrEmpty($Healthcheck.StartPeriod)) {
            $cmd += "--health-start-period=" + $Healthcheck.StartPeriod
        }
        $cmd += $("--health-cmd=`'" + $Healthcheck.Test + "`'")
    }

    $cmd += @('--name', $Service.ContainerName, $Service.Image)
    $cmd += $Service.Command

    return $cmd
}

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

function Start-DockerService
{
    param(
        [DockerService] $Service,
        [switch] $Remove
    )

    if (Get-ContainerExists -Name $Service.ContainerName) {
        if (Get-ContainerIsRunning -Name $Service.ContainerName) {
            docker stop $Service.ContainerName | Out-Null
        }

        if ($Remove) {
            docker rm $Service.ContainerName | Out-Null
        }
    }

    $RunCommand = (Get-DockerRunCommand -Service $Service) | Join-String -Separator " "

    $id = Invoke-Expression $RunCommand

    if (Get-ContainerIsRunning -Name $Service.ContainerName){
        Write-Host "$($Service.ContainerName) successfully started"
    } else {
        Write-Error -Message "Error starting $($Service.ContainerName)"
    }
}

function Start-WaykDen
{
    param(
        [string] $Path
    )

    $DenNetwork = "den-network"
    $MongoVolume = "den-mongodata"
    $Services = Get-WaykDenService -Path:$Path -DenNetwork $DenNetwork -MongoVolume $MongoVolume

    # pull docker images
    foreach ($service in $services) {
        docker pull $service.Image | Out-Null
    }

    # create docker network
    New-DockerNetwork -Name $DenNetwork -Force

    # create docker volume
    New-DockerVolume -Name $MongoVolume -Force

    # start containers
    foreach ($Service in $Services) {
        Start-DockerService -Service $Service -Remove
    }
}

function Stop-WaykDen
{
    param(
        [string] $Path
    )

    $Services = Get-WaykDenService -Path:$Path

    # stop containers
    foreach ($Service in $Services) {
        Write-Host "Stopping $($Service.ContainerName)"
        docker stop $Service.ContainerName | Out-Null
    }
}

function Restart-WaykDen
{
    param(
        [string] $Path
    )

    Stop-WaykDen -Path:$Path
    Start-WaykDen -Path:$Path
}

Export-ModuleMember -Function Start-WaykDen, Stop-WaykDen, Restart-WaykDen
