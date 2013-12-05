function Get-Certificate($thumbprint)
{
    get-item cert:\localmachine\trustedpeople\$thumbprint
}

function Encrypt-Envelope($unprotectedcontent, $cert)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.Security") | Out-Null
    $utf8content = [Text.Encoding]::UTF8.GetBytes($unprotectedcontent)
    $content = New-Object Security.Cryptography.Pkcs.ContentInfo -argumentList (,$utf8content)
    $env = New-Object Security.Cryptography.Pkcs.EnvelopedCms $content
    $recpient = (New-Object System.Security.Cryptography.Pkcs.CmsRecipient($cert))
    $env.Encrypt($recpient)
    $base64string = [Convert]::ToBase64String($env.Encode())
    return $base64string
}

function Decrypt-Envelope($base64string)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.Security") | Out-Null
    $content = [Convert]::FromBase64String($base64string)
    $env = New-Object Security.Cryptography.Pkcs.EnvelopedCms
    $env.Decode($content)
    $env.Decrypt()
    $utf8content = [text.encoding]::UTF8.getstring($env.ContentInfo.Content)
    return $utf8content
}