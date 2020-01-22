
class WaykDenConfig
{
    # Mandatory
    [string] $Realm
    [string] $ExternalUrl

    # Server
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
}

function ConvertTo-PascalCase
{
    [OutputType('System.String')]
    param(
        [Parameter(Position=0)]
        [string] $Value
    )

    # https://devblogs.microsoft.com/oldnewthing/20190909-00/?p=102844
    return [regex]::replace($Value.ToLower(), '(^|_)(.)', { $args[0].Groups[2].Value.ToUpper()})
}

function ConvertTo-SnakeCase
{
    [OutputType('System.String')]
    param(
        [Parameter(Position=0)]
        [string] $Value
    )

    return [regex]::replace($Value, '([A-Z])(.)', { '_' + $args[0].Groups[0].Value.ToLower() }).Trim('_')
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

    $snake_obj = New-Object -TypeName 'PSObject'

    $config.PSObject.Properties | ForEach-Object {
        $name = ConvertTo-SnakeCase -Value ($_.Name | Out-String).Trim()
        $value = ($_.Value | Out-String).Trim()
        if (![string]::IsNullOrEmpty($value)) {
            $snake_obj | Add-Member -MemberType NoteProperty -Name $name -Value $value
        }
    }
 
    ConvertTo-Yaml $snake_obj -OutFile $ConfigFile -Force:$Force
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

    $snake_obj = New-Object -TypeName 'PSObject'

    $config.PSObject.Properties | ForEach-Object {
        $name = ConvertTo-SnakeCase -Value ($_.Name | Out-String).Trim()
        $value = ($_.Value | Out-String).Trim()
        if (![string]::IsNullOrEmpty($value)) {
            $snake_obj | Add-Member -MemberType NoteProperty -Name $name -Value $value
        }
    }
 
    ConvertTo-Yaml $snake_obj -OutFile $ConfigFile -Force:$Force

    #ConvertTo-Yaml $config -OutFile $ConfigFile -Force
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

    return $config
}

Export-ModuleMember -Function New-WaykDenConfig, Set-WaykDenConfig, Get-WaykDenConfig
