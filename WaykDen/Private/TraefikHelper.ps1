
function New-TraefikToml
{
    [OutputType('System.String')]
    param(
        [string] $Port,
        [string] $Protocol,
        [string] $DenLucidUrl,
        [string] $DenRouterUrl,
        [string] $DenServerUrl,
        [string] $CertFile,
        [string] $KeyFile
    )

    $TraefikPort = $Port
    $TraefikEntrypoint = $Protocol
    $TraefikCertFile = $CertFile
    $TraefikKeyFile = $KeyFile

    $templates = @()

    $templates += '
logLevel = "INFO"

[file]

[entryPoints]
    [entryPoints.${TraefikEntrypoint}]
    address = ":${TraefikPort}"'

    if ($Protocol -eq 'https') {
        $templates += '
        [entryPoints.${TraefikEntrypoint}.tls]
            [entryPoints.${TraefikEntrypoint}.tls.defaultCertificate]
            certFile = "${TraefikCertFile}"
            keyFile = "${TraefikKeyFile}"'
    }

    $templates += '
        [entryPoints.${TraefikEntrypoint}.redirect]
        regex = "^http(s)?://([^/]+)/?`$"
        replacement = "http`$1://`$2/web"
    '

    $templates += '
[frontends]
    [frontends.lucid]
    passHostHeader = true
    backend = "lucid"
    entrypoints = ["${TraefikEntrypoint}"]
        [frontends.lucid.routes.lucid]
        rule = "PathPrefixStrip:/lucid"

    [frontends.lucidop]
    passHostHeader = true
    backend = "lucid"
    entrypoints = ["${TraefikEntrypoint}"]
        [frontends.lucidop.routes.lucidop]
        rule = "PathPrefix:/op"

    [frontends.lucidauth]
    passHostHeader = true
    backend = "lucid"
    entrypoints = ["${TraefikEntrypoint}"]
        [frontends.lucidauth.routes.lucidauth]
        rule = "PathPrefix:/auth"

    [frontends.router]
    passHostHeader = true
    backend = "router"
    entrypoints = ["${TraefikEntrypoint}"]
        [frontends.router.routes.router]
        rule = "PathPrefixStrip:/cow"

    [frontends.server]
    passHostHeader = true
    backend = "server"
    entrypoints = ["${TraefikEntrypoint}"]
'

    $templates += '
[backends]
    [backends.lucid]
        [backends.lucid.servers.lucid]
        url = "${DenLucidUrl}"
        weight = 10

    [backends.router]
        [backends.router.servers.router]
        url = "${DenRouterUrl}"
        method="drr"
        weight = 10

    [backends.server]
        [backends.server.servers.server]
        url = "${DenServerUrl}"
        weight = 10
        method="drr"
'

    $template = -Join $templates

    return Invoke-Expression "@`"`r`n$template`r`n`"@"
}