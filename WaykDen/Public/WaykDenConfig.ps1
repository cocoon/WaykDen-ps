
. "$PSScriptRoot/../Private/CaseHelper.ps1"
. "$PSScriptRoot/../Private/RandomGenerator.ps1"

class WaykDenConfig
{
    # Mandatory
    [string] $Realm
    [string] $ExternalUrl

    # Den Server
    [string] $WaykDenPort
    [string] $Certificate
    [string] $PrivateKey
    [string] $SyslogServer

    # MongoDB
    [string] $MongoUrl

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
}

function Set-ConfigString
{
    param(
        [Parameter(Position=0)]
        $config,
        [Parameter(Position=1)]
        [string] $Name,
        [Parameter(Position=2)]
        [string] $Value
    )

    if (![string]::IsNullOrEmpty($Value)) {
        $config.$Name = $Value
    }
}

function Get-ConfigString
{
    [OutputType('System.String')]
    param(
        [Parameter(Position=0)]
        $yaml,
        [Parameter(Position=1)]
        [string] $Name
    )

    $Name = ConvertTo-SnakeCase -Value $Name

    if (![string]::IsNullOrEmpty($yaml.$Name)) {
        return ($yaml.$Name | Out-String).Trim()
    } else {
        return $null
    }
}

function New-WaykDenConfig
{
    param(
        [string] $Path,
    
        [Parameter(Mandatory=$true)]
        [string] $Realm,
        [Parameter(Mandatory=$true)]
        [string] $ExternalUrl,

        # Server
        [string] $WaykDenPort,
        [string] $Certificate,
        [string] $PrivateKey,
        [string] $SyslogServer,

        # MongoDB
        [string] $MongoUrl,

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

    $config = [WaykDenConfig]::new()
    
    # Mandatory
    Set-ConfigString $config 'Realm' $Realm
    Set-ConfigString $config 'ExternalUrl' $ExternalUrl

    # Server
    Set-ConfigString $config 'WaykDenPort' $WaykDenPort
    Set-ConfigString $config 'Certificate' $Certificate
    Set-ConfigString $config 'PrivateKey' $PrivateKey
    Set-ConfigString $config 'SyslogServer' $SyslogServer

    # MongoDB
    Set-ConfigString $config 'MongoUrl' $MongoUrl
    
    # Jet
    Set-ConfigString $config 'JetRelayUrl' $JetRelayUrl

    # LDAP
    Set-ConfigString $config 'LdapServerUrl' $LdapServerUrl
    Set-ConfigString $config 'LdapUsername' $LdapUsername
    Set-ConfigString $config 'LdapPassword' $LdapPassword
    Set-ConfigString $config 'LdapUserGroup' $LdapUserGroup
    Set-ConfigString $config 'LdapServerType' $LdapServerType
    Set-ConfigString $config 'LdapBaseDn' $LdapBaseDn

    # NATS
    Set-ConfigString $config 'NatsUrl' $NatsUrl
    Set-ConfigString $config 'NatsUsername' $NatsUsername
    Set-ConfigString $config 'NatsPassword' $NatsPassword

    # Redis
    Set-ConfigString $config 'RedisUrl' $RedisUrl
    Set-ConfigString $config 'RedisPassword' $RedisPassword

    # Internal API keys
    Set-ConfigString $config 'DenApiKey' $DenApiKey
    Set-ConfigString $config 'PickyApiKey' $PickyApiKey
    Set-ConfigString $config 'LucidApiKey' $LucidApiKey
    Set-ConfigString $config 'LucidAdminUsername' $LucidAdminUsername
    Set-ConfigString $config 'LucidAdminSecret' $LucidAdminSecret

    ConvertTo-Yaml -Data (ConvertTo-SnakeCaseObject -Object $config) -OutFile $ConfigFile -Force:$Force
}

function Set-WaykDenConfig
{
    param(
        [string] $Path,
    
        [string] $Realm,
        [string] $ExternalUrl,

        # Server
        [string] $WaykDenPort,
        [string] $Certificate,
        [string] $PrivateKey,
        [string] $SyslogServer,

        # MongoDB
        [string] $MongoUrl,

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

    $config = Get-WaykDenConfig -Path $Path

    New-Item -Path $Path -ItemType "Directory" -Force | Out-Null
    $ConfigFile = Join-Path $Path "wayk-den.yml"

    # Mandatory
    Set-ConfigString $config 'Realm' $Realm
    Set-ConfigString $config 'ExternalUrl' $ExternalUrl

    # Server
    Set-ConfigString $config 'WaykDenPort' $WaykDenPort
    Set-ConfigString $config 'Certificate' $Certificate
    Set-ConfigString $config 'PrivateKey' $PrivateKey
    Set-ConfigString $config 'SyslogServer' $SyslogServer

    # MongoDB
    Set-ConfigString $config 'MongoUrl' $MongoUrl
    
    # Jet
    Set-ConfigString $config 'JetRelayUrl' $JetRelayUrl

    # LDAP
    Set-ConfigString $config 'LdapServerUrl' $LdapServerUrl
    Set-ConfigString $config 'LdapUsername' $LdapUsername
    Set-ConfigString $config 'LdapPassword' $LdapPassword
    Set-ConfigString $config 'LdapUserGroup' $LdapUserGroup
    Set-ConfigString $config 'LdapServerType' $LdapServerType
    Set-ConfigString $config 'LdapBaseDn' $LdapBaseDn

    # NATS
    Set-ConfigString $config 'NatsUrl' $NatsUrl
    Set-ConfigString $config 'NatsUsername' $NatsUsername
    Set-ConfigString $config 'NatsPassword' $NatsPassword

    # Redis
    Set-ConfigString $config 'RedisUrl' $RedisUrl
    Set-ConfigString $config 'RedisPassword' $RedisPassword
 
    ConvertTo-Yaml -Data (ConvertTo-SnakeCaseObject -Object $config) -OutFile $ConfigFile -Force:$Force
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
    
    # Mandatory
    $config.Realm = Get-ConfigString $yaml 'Realm'
    $config.ExternalUrl = Get-ConfigString $yaml 'ExternalUrl'

    # Server
    $config.WaykDenPort = Get-ConfigString $yaml 'WaykDenPort'
    $config.Certificate = Get-ConfigString $yaml 'Certificate'
    $config.PrivateKey = Get-ConfigString $yaml 'PrivateKey'
    $config.SyslogServer = Get-ConfigString $yaml 'SyslogServer'

    # MongoDB
    $config.MongoUrl = Get-ConfigString $yaml 'MongoUrl'

    # Jet
    $config.JetRelayUrl = Get-ConfigString $yaml 'JetRelayUrl'

    # LDAP
    $config.LdapServerUrl = Get-ConfigString $yaml 'LdapServerUrl'
    $config.LdapUsername = Get-ConfigString $yaml 'LdapUsername'
    $config.LdapPassword = Get-ConfigString $yaml 'LdapPassword'
    $config.LdapUserGroup = Get-ConfigString $yaml 'LdapUserGroup'
    $config.LdapServerType = Get-ConfigString $yaml 'LdapServerType'
    $config.LdapBaseDn = Get-ConfigString $yaml 'LdapBaseDn'

    # NATS
    $config.NatsUrl = Get-ConfigString $yaml 'NatsUrl'
    $config.NatsUsername = Get-ConfigString $yaml 'NatsUsername'
    $config.NatsPassword = Get-ConfigString $yaml 'NatsPassword'

    # Redis
    $config.RedisUrl = Get-ConfigString $yaml 'RedisUrl'
    $config.RedisPassword = Get-ConfigString $yaml 'RedisPassword'

    # Internal API keys
    $config.DenApiKey = Get-ConfigString $yaml 'DenApiKey'
    $config.PickyApiKey = Get-ConfigString $yaml 'PickyApiKey'
    $config.LucidApiKey = Get-ConfigString $yaml 'LucidApiKey'
    $config.LucidAdminUsername = Get-ConfigString $yaml 'LucidAdminUsername'
    $config.LucidAdminSecret = Get-ConfigString $yaml 'LucidAdminSecret'

    return $config
}

Export-ModuleMember -Function New-WaykDenConfig, Set-WaykDenConfig, Get-WaykDenConfig
