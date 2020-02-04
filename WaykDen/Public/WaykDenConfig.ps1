
. "$PSScriptRoot/../Private/CaseHelper.ps1"
. "$PSScriptRoot/../Private/YamlHelper.ps1"
. "$PSScriptRoot/../Private/TraefikHelper.ps1"
. "$PSScriptRoot/../Private/RandomGenerator.ps1"
. "$PSScriptRoot/../Private/CertificateHelper.ps1"

class WaykDenConfig
{
    # Server
    [string] $Realm
    [string] $ExternalUrl
    [string] $ListenerUrl
    [string] $ServerMode
    [int] $ServerCount

    # MongoDB
    [string] $MongoUrl
    [string] $MongoVolume
    [bool] $MongoExternal

    # Jet
    [string] $JetRelayUrl

    # LDAP
    [string] $LdapServerUrl
    [string] $LdapUsername
    [string] $LdapPassword
    [string] $LdapUserGroup
    [string] $LdapServerType
    [string] $LdapBaseDn

    # NATS
    [string] $NatsUrl
    [string] $NatsUsername
    [string] $NatsPassword
    
    # Redis
    [string] $RedisUrl
    [string] $RedisPassword

    # Internal API keys
    [string] $DenApiKey
    [string] $PickyApiKey
    [string] $LucidApiKey
    [string] $LucidAdminUsername
    [string] $LucidAdminSecret

    # Internal settings
    [string] $DockerNetwork
    [string] $DockerPlatform
    [string] $SyslogServer
    [string] $JetServerUrl
    [string] $DenPickyUrl
    [string] $DenLucidUrl
    [string] $DenServerUrl
    [string] $DenRouterUrl
}

function Expand-WaykDenConfig
{
    param(
        [WaykDenConfig] $Config
    )

    $DockerNetworkDefault = "den-network"
    $MongoUrlDefault = "mongodb://den-mongo:27017"
    $MongoVolumeDefault = "den-mongodata"
    $ServerModeDefault = "Private"
    $ListenerUrlDefault = "http://0.0.0.0:4000"
    $JetServerUrlDefault = "api.jet-relay.net:8080"
    $JetRelayUrlDefault = "https://api.jet-relay.net"
    $DenPickyUrlDefault = "http://den-picky:12345"
    $DenLucidUrlDefault = "http://den-lucid:4242"
    $DenServerUrlDefault = "http://den-server:10255"
    $DenRouterUrlDefault = "http://den-server:4491"

    if (-Not $config.DockerNetwork) {
        $config.DockerNetwork = $DockerNetworkDefault
    }

    if (-Not $config.DockerPlatform) {
        if (Get-IsWindows) {
            $config.DockerPlatform = "windows"
        } else {
            $config.DockerPlatform = "linux"
        }
    }

    if (-Not $config.ServerMode) {
        $config.ServerMode = $ServerModeDefault
    }

    if (-Not $config.ServerCount) {
        $config.ServerCount = 1
    }

    if (-Not $config.ListenerUrl) {
        $config.ListenerUrl = $ListenerUrlDefault
    }

    if (-Not $config.MongoUrl) {
        $config.MongoUrl = $MongoUrlDefault
    }

    if (-Not $config.MongoVolume) {
        $config.MongoVolume = $MongoVolumeDefault
    }

    if (-Not $config.JetServerUrl) {
        $config.JetServerUrl = $JetServerUrlDefault
    }

    if (-Not $config.JetRelayUrl) {
        $config.JetRelayUrl = $JetRelayUrlDefault
    }

    if (-Not $config.DenPickyUrl) {
        $config.DenPickyUrl = $DenPickyUrlDefault
    }

    if (-Not $config.DenLucidUrl) {
        $config.DenLucidUrl = $DenLucidUrlDefault
    }

    if (-Not $config.DenServerUrl) {
        $config.DenServerUrl = $DenServerUrlDefault
    }

    if (-Not $config.DenRouterUrl) {
        $config.DenRouterUrl = $DenRouterUrlDefault
    }
}

function Export-TraefikToml()
{
    param(
        [string] $Path
    )

    if ([string]::IsNullOrEmpty($Path)) {
        $Path = Get-Location
    }

    $config = Get-WaykDenConfig -Path:$Path
    Expand-WaykDenConfig $config

    $TraefikPath = Join-Path $Path "traefik"
    New-Item -Path $TraefikPath -ItemType "Directory" -Force | Out-Null

    $TraefikTomlFile = Join-Path $TraefikPath "traefik.toml"

    $TraefikToml = New-TraefikToml -Platform $config.DockerPlatform -ListenerUrl $config.ListenerUrl `
        -DenLucidUrl $config.DenLucidUrl -DenRouterUrl $config.DenRouterUrl -DenServerUrl $config.DenServerUrl
    Set-Content -Path $TraefikTomlFile -Value $TraefikToml
}

function New-WaykDenConfig
{
    param(
        [string] $Path,
    
        # Server
        [Parameter(Mandatory=$true)]
        [string] $Realm,
        [Parameter(Mandatory=$true)]
        [string] $ExternalUrl,
        [string] $ListenerUrl,
        [string] $ServerMode,
        [int] $ServerCount,

        # MongoDB
        [string] $MongoUrl,
        [string] $MongoVolume,
        [bool] $MongoExternal,

        # Jet
        [string] $JetRelayUrl,

        # LDAP
        [string] $LdapServerUrl,
        [string] $LdapUsername,
        [string] $LdapPassword,
        [string] $LdapUserGroup,
        [string] $LdapServerType,
        [string] $LdapBaseDn,

        # NATS
        [string] $NatsUrl,
        [string] $NatsUsername,
        [string] $NatsPassword,
        
        # Redis
        [string] $RedisUrl,
        [string] $RedisPassword,

        [switch] $Force
    )

    if ([string]::IsNullOrEmpty($Path)) {
        $Path = Get-Location
    }

    New-Item -Path $Path -ItemType "Directory" -Force | Out-Null
    $ConfigFile = Join-Path $Path "wayk-den.yml"

    $DenApiKey = New-RandomString -Length 32
    $PickyApiKey = New-RandomString -Length 32
    $LucidApiKey = New-RandomString -Length 32
    $LucidAdminUsername = New-RandomString -Length 16
    $LucidAdminSecret = New-RandomString -Length 10

    $DenServerPath = Join-Path $Path "den-server"
    $DenPublicKeyFile = Join-Path $DenServerPath "den-public.pem"
    $DenPrivateKeyFile = Join-Path $DenServerPath "den-private.key"
    New-Item -Path $DenServerPath -ItemType "Directory" -Force | Out-Null

    if (!((Test-Path -Path $DenPublicKeyFile -PathType "Leaf") -and
          (Test-Path -Path $DenPrivateKeyFile -PathType "Leaf"))) {
            $KeyPair = New-RsaKeyPair -KeySize 2048
            Set-Content -Path $DenPublicKeyFile -Value $KeyPair.PublicKey -Force
            Set-Content -Path $DenPrivateKeyFile -Value $KeyPair.PrivateKey -Force
    }

    $config = [WaykDenConfig]::new()
    
    $properties = [WaykDenConfig].GetProperties() | ForEach-Object { $_.Name }
    foreach ($param in $PSBoundParameters.GetEnumerator()) {
        if ($properties -Contains $param.Key) {
            $config.($param.Key) = $param.Value
        }
    }

    ConvertTo-Yaml -Data (ConvertTo-SnakeCaseObject -Object $config) -OutFile $ConfigFile -Force:$Force

    Export-TraefikToml -Path:$Path
}

function Set-WaykDenConfig
{
    param(
        [string] $Path,
    
        [string] $Realm,
        [string] $ExternalUrl,
        [string] $ListenerUrl,
        [string] $ServerMode,
        [int] $ServerCount,

        # MongoDB
        [string] $MongoUrl,
        [string] $MongoVolume,
        [bool] $MongoExternal,

        # Jet
        [string] $JetRelayUrl,

        # LDAP
        [string] $LdapServerUrl,
        [string] $LdapUsername,
        [string] $LdapPassword,
        [string] $LdapUserGroup,
        [string] $LdapServerType,
        [string] $LdapBaseDn,

        # NATS
        [string] $NatsUrl,
        [string] $NatsUsername,
        [string] $NatsPassword,
        
        # Redis
        [string] $RedisUrl,
        [string] $RedisPassword,

        [string] $WrongParam,

        [switch] $Force
    )

    if ([string]::IsNullOrEmpty($Path)) {
        $Path = Get-Location
    }

    $config = Get-WaykDenConfig -Path $Path

    New-Item -Path $Path -ItemType "Directory" -Force | Out-Null
    $ConfigFile = Join-Path $Path "wayk-den.yml"

    $properties = [WaykDenConfig].GetProperties() | ForEach-Object { $_.Name }
    foreach ($param in $PSBoundParameters.GetEnumerator()) {
        if ($properties -Contains $param.Key) {
            $config.($param.Key) = $param.Value
        }
    }
 
    # always force overwriting wayk-den.yml when updating the config file
    ConvertTo-Yaml -Data (ConvertTo-SnakeCaseObject -Object $config) -OutFile $ConfigFile -Force

    Export-TraefikToml -Path:$Path
}

function Get-WaykDenConfig
{
    [OutputType('WaykDenConfig')]
    param(
        [string] $Path
    )

    if ([string]::IsNullOrEmpty($Path)) {
        $Path = Get-Location
    }

    $ConfigFile = Join-Path $Path "wayk-den.yml"
    $ConfigData = Get-Content -Path $ConfigFile -Raw
    $yaml = ConvertFrom-Yaml -Yaml $ConfigData -UseMergingParser -AllDocuments -Ordered

    $config = [WaykDenConfig]::new()

    [WaykDenConfig].GetProperties() | ForEach-Object {
        $Name = $_.Name
        $snake_name = ConvertTo-SnakeCase -Value $Name
        if ($yaml.Contains($snake_name)) {
            if ($yaml.$snake_name -is [string]) {
                if (![string]::IsNullOrEmpty($yaml.$snake_name)) {
                    $config.$Name = ($yaml.$snake_name).Trim()
                }
            } else {
                $config.$Name = $yaml.$snake_name
            }
        }
    }

    return $config
}

Export-ModuleMember -Function New-WaykDenConfig, Set-WaykDenConfig, Get-WaykDenConfig
