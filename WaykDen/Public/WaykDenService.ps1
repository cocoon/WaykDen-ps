
. "$PSScriptRoot/../Private/PlatformHelper.ps1"
. "$PSScriptRoot/../Private/DockerHelper.ps1"
. "$PSScriptRoot/../Private/TraefikHelper.ps1"

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
        [WaykDenConfig] $Config
    )

    if ([string]::IsNullOrEmpty($Path)) {
        $Path = Get-Location
    }

    $images = Get-WaykDenImage

    $Realm = $config.Realm
    $ExternalUrl = $config.ExternalUrl
    $TraefikPort = $config.WaykDenPort
    $MongoUrl = $config.MongoUrl
    $DenNetwork = $config.DockerNetwork
    $JetServerUrl = $config.JetServerUrl
    $JetRelayUrl = $config.JetRelayUrl

    $DenApiKey = $config.DenApiKey
    $PickyApiKey = $config.PickyApiKey
    $LucidApiKey = $config.LucidApiKey
    $LucidAdminUsername = $config.LucidAdminUsername
    $LucidAdminSecret = $config.LucidAdminSecret

    $DenPickyUrl = $config.DenPickyUrl
    $DenLucidUrl = $config.DenLucidUrl
    $DenServerUrl = $config.DenServerUrl

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
        "LUCID_ACCOUNT__LOGIN_URL" = "$DenServerUrl/account/login";
        "LUCID_ACCOUNT__REFRESH_USER_URL" = "$DenServerUrl/account/refresh";
        "LUCID_ACCOUNT__FORGOT_PASSWORD_URL" = "$DenServerUrl/account/forgot";
        "LUCID_ACCOUNT__SEND_ACTIVATION_EMAIL_URL" = "$DenServerUrl/account/activation";
    }
    $DenLucid.Healthcheck = [DockerHealthcheck]::new("curl -sS $DenLucidUrl/health")

    # den-server service
    $DenServer = [DockerService]::new()
    $DenServer.ContainerName = 'den-server'
    $DenServer.Image = $images[$DenServer.ContainerName]
    $DenServer.DependsOn = @("den-mongo", 'den-traefik')
    $DenServer.Networks += $DenNetwork
    $DenServer.Environment = [ordered]@{
        "PICKY_REALM" = $Realm;
        "PICKY_URL" = $DenPickyUrl;
        "PICKY_API_KEY" = $PickyApiKey;
        "DB_URL" = $MongoUrl;
        "AUDIT_TRAILS" = "true";
        "LUCID_AUTHENTICATION_KEY" = $LucidApiKey;
        "DEN_ROUTER_EXTERNAL_URL" = "$ExternalUrl/cow";
        "LUCID_INTERNAL_URL" = $DenLucidUrl;
        "LUCID_EXTERNAL_URL" = "$ExternalUrl/lucid";
        "DEN_LOGIN_REQUIRED" = "false";
        "DEN_PRIVATE_KEY_FILE" = "/etc/den-server/den-private.key";
        "DEN_PUBLIC_KEY_FILE" = "/etc/den-server/den-public.pem";
        "JET_SERVER_URL" = $JetServerUrl;
        "JET_RELAY_URL" = $JetRelayUrl;
        "DEN_API_KEY" = $DenApiKey;
    }
    $DenServer.Volumes = @("$Path/den-server:/etc/den-server:ro")
    $DenServer.Command = "-m onprem -l trace"
    $DenServer.Healthcheck = [DockerHealthcheck]::new("curl -sS $DenServerUrl/health")

    # den-traefik service
    $DenTraefik = [DockerService]::new()
    $DenTraefik.ContainerName = 'den-traefik'
    $DenTraefik.Image = $images[$DenTraefik.ContainerName]
    $DenTraefik.Networks += $DenNetwork
    $DenTraefik.Volumes = @("$Path/traefik:/etc/traefik")
    $DenTraefik.Command = "--file --configFile=/etc/traefik/traefik.toml"
    $DenTraefik.Ports = @("4000:$TraefikPort")

    $Services = @($DenMongo, $DenPicky, $DenLucid, $DenServer, $DenTraefik)
    return $Services
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

function Start-DockerService
{
    param(
        [DockerService] $Service,
        [switch] $Remove,
        [switch] $Verbose
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

    if ($Verbose) {
        Write-Host $RunCommand
    }

    $id = Invoke-Expression $RunCommand

    if ($Service.Healthcheck) {
        Wait-ContainerHealthy -Name $Service.ContainerName | Out-Null
    }

    if (Get-ContainerIsRunning -Name $Service.ContainerName){
        Write-Host "$($Service.ContainerName) successfully started"
    } else {
        Write-Error -Message "Error starting $($Service.ContainerName)"
    }
}

function Start-WaykDen
{
    param(
        [string] $Path,
        [switch] $Verbose
    )

    $config = Get-WaykDenConfig -Path:$Path
    Expand-WaykDenConfig -Config $config

    $Services = Get-WaykDenService -Path:$Path -Config $config

    # pull docker images
    foreach ($service in $services) {
        docker pull $service.Image | Out-Null
    }

    # create docker network
    New-DockerNetwork -Name $config.DockerNetwork -Force

    # create docker volume
    New-DockerVolume -Name $config.MongoVolume -Force

    # start containers
    foreach ($Service in $Services) {
        Start-DockerService -Service $Service -Remove -Verbose:$Verbose
    }
}

function Stop-WaykDen
{
    param(
        [string] $Path,
        [switch] $Remove
    )

    $config = Get-WaykDenConfig -Path:$Path
    Expand-WaykDenConfig -Config $config

    $Services = Get-WaykDenService -Path:$Path -Config $config

    # stop containers
    foreach ($Service in $Services) {
        Write-Host "Stopping $($Service.ContainerName)"
        docker stop $Service.ContainerName | Out-Null

        if ($Remove) {
            docker rm $Service.ContainerName | Out-Null
        }
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
