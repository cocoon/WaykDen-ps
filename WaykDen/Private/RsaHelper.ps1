

function New-RsaKeyPair
{
    param(
        [int] $KeySize = 2048
    )

    $rsa = [System.Security.Cryptography.RSA]::Create($KeySize)

    $stream = [System.IO.MemoryStream]::new()
    $writer = [PemUtils.PemWriter]::new($stream)

    $stream.SetLength(0)
    $writer.WritePublicKey($rsa);
    $stream.Seek(0, [System.IO.SeekOrigin]::Begin) | Out-Null
    $PublicKey = [System.IO.StreamReader]::new($stream).ReadToEnd()

    $stream.SetLength(0)
    $writer.WritePrivateKey($rsa)
    $stream.Seek(0, [System.IO.SeekOrigin]::Begin) | Out-Null
    $PrivateKey = [System.IO.StreamReader]::new($stream).ReadToEnd()

    return [PSCustomObject]@{
        PublicKey = $PublicKey
        PrivateKey = $PrivateKey
    }
}
