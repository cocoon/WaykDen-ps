
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
}

function Start-WaykDen
{
    param(
        [string] $Path
    )

    $config = Get-WaykDenConfig -Path:$Path

    $images = Get-WaykDenImage
    $DenNetwork = "den-network"

    $Realm = $config.Realm
    $ExternalUrl = $config.ExternalUrl

    $MongoUrl = $config.MongoUrl
    $MongoVolume = "den-mongodata"

    if ([string]::IsNullOrEmpty($MongoUrl)) {
        $MongoUrl = "mongodb://den-mongo:27017"
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
    $den_mongo = [DockerService]::new()
    $den_mongo.ContainerName = 'den-mongo'
    $den_mongo.Image = $images[$den_mongo.ContainerName]
    $den_mongo.Networks += $DenNetwork
    $den_mongo.Volumes = @("$MongoVolume`:/data/db")

    # den-picky service
    $den_picky = [DockerService]::new()
    $den_picky.ContainerName = 'den-picky'
    $den_picky.Image = $images[$den_picky.ContainerName]
    $den_picky.DependsOn = @("den-mongo")
    $den_picky.Networks += $DenNetwork
    $den_picky.Environment = [ordered]@{
        "PICKY_REALM" = $Realm;
        "PICKY_API_KEY" = $PickyApiKey;
        "PICKY_DATABASE_URL" = $MongoUrl;
    }

    # den-lucid service
    $den_lucid = [DockerService]::new()
    $den_lucid.ContainerName = 'den-lucid'
    $den_lucid.Image = $images[$den_lucid.ContainerName]
    $den_lucid.DependsOn = @("den-mongo")
    $den_lucid.Networks += $DenNetwork
    $den_lucid.Environment = [ordered]@{
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

    # den-server service
    $den_server = [DockerService]::new()
    $den_server.ContainerName = 'den-server'
    $den_server.Image = $images[$den_server.ContainerName]
    $den_server.DependsOn = @("den-mongo", 'traefik')
    $den_server.Networks += $DenNetwork
    $den_server.Environment = [ordered]@{
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
    $den_server.Volumes = @("den-server:/etc/den-server:ro")
    $den_server.Command = "--db_url $MongoUrl -m onprem -l trace"

    # den-traefik service
    $den_traefik = [DockerService]::new()
    $den_traefik.ContainerName = 'den-traefik'
    $den_traefik.Image = $images[$den_traefik.ContainerName]
    $den_traefik.Networks += $DenNetwork
    $den_traefik.Volumes = @("traefik:/etc/traefik")
    $den_traefik.Command = "--file --configFile=/etc/traefik/traefik.toml"
    $den_traefik.Ports = @("4000:$TraefikPort")

    $services = @($den_mongo, $den_picky, $den_lucid, $den_server, $den_traefik)

    # pull docker images
    foreach ($service in $services) {
        docker pull $service.Image
    }

    # create docker network
    New-DockerNetwork -Name $DenNetwork -Force

    # create docker volume
    New-DockerVolume -Name $MongoVolume -Force
}

Export-ModuleMember -Function Start-WaykDen
