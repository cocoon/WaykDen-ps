
function Import-WaykDenCertificate
{
    param(
        [string] $Path,

        [string] $CertificateFile,
        [string] $PrivateKeyFile
    )

    if ([string]::IsNullOrEmpty($Path)) {
        $Path = Get-Location
    }

    $config = Get-WaykDenConfig -Path:$Path

    $CertificateData = Get-Content -Raw -Path $CertificateFile
    $PrivateKeyData = Get-Content -Raw -Path $PrivateKeyFile

    $TraefikPath = Join-Path $Path "traefik"
    New-Item -Path $TraefikPath -ItemType "Directory" -Force | Out-Null

    $TraefikPemFile = Join-Path $TraefikPath "den-server.pem"
    $TraeficKeyFile = Join-Path $TraefikPath "den-server.key"

    Set-Content -Path $TraefikPemFile -Value $CertificateData -Force
    Set-Content -Path $TraeficKeyFile -Value $PrivateKeyData -Force
}

Export-ModuleMember -Function Import-WaykDenCertificate
