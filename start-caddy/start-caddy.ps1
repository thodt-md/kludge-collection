$OpenSSLSource = "https://indy.fulgan.com/SSL/openssl-1.0.1f-i386-win32.zip";
$CaddySource = "https://caddyserver.com/download/windows/386";

if ($ENV:PROCESSOR_ARCHITECTURE -Eq "AMD64")
{
  $OpenSSLSource = "https://indy.fulgan.com/SSL/openssl-1.0.1f-x64_86-win64.zip";
  $CaddySource = "https://caddyserver.com/download/windows/amd64";
}

$OpenSSLExe = "openssl.exe";

$CertSubject = "/C=AU/ST=Some-State/O=Internet Widgits Pty Ltd/CN=localhost";
$CurrentDir = $PSScriptRoot;
$CaddyHome = "$CurrentDir\.caddy";
$KeysDir = "$CaddyHome\keys";
$CaddyExe = "$CaddyHome\caddy.exe";
$TempPath = "$env:TEMP\start-caddy";

$ProxyPort = 8443;
$TargetPort = 8080;

function EnsureDirectoryExists($Path) {
    if (!(Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null;
    }
}

function MissingExecutable([string] $Name)
{
    return ((Get-Command $Name -ErrorAction SilentlyContinue) -eq $null);
}

function GetFile([string] $Url, [string] $Dest)
{
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
    (New-Object Net.WebClient).DownloadFile($Url, $Dest);
}

function Unzip([string] $Archive, [string] $Dest)
{
    Echo "Unpacking $Archive to $Dest";
    Add-Type -AssemblyName System.IO.Compression.FileSystem;

    if (Test-Path $Dest)
    {
        Echo "$Dest exists, removing...";
        Rmdir -Path $Dest -Recurse;
    }

    EnsureDirectoryExists $Dest;
    [IO.Compression.ZipFile]::ExtractToDirectory($Archive, $Dest);
}

function EnsureOpenSSLPresent()
{
    if (MissingExecutable $OpenSSLExe) {
        Echo "OpenSSL is missing, downloading...";
        EnsureDirectoryExists $TempPath;
        GetFile -Url $OpenSSLSource -Dest "$TempPath\openssl.zip";
        Unzip -Archive "$TempPath\openssl.zip" -Dest "$TempPath\openssl";
        $script:OpenSSLExe = "$TempPath\openssl\openssl.exe";
    }
}

function CreateOpenSSLConfig()
{
    Echo "Creating OpenSSL config"
    EnsureDirectoryExists "$TempPath\openssl";
    WriteOpenSSLConfig -Path "$TempPath\openssl\openssl.cnf";
    $env:OPENSSL_CONF = "$TempPath\openssl\openssl.cnf";
}

function WriteOpenSSLConfig([string] $Path)
{
# gz.b64 version of http://web.mit.edu/crypto/openssl.cnf
$Encoded = @"
H4sICEXc4FkAA29wZW5zc2wuY25mLjEArVltb9s4Ev4c/QpuukCaRermpS32DPiD6ybbXNMkiJO2
i6IwaIm22cikjqRi+w733+8ZkpJlR+ne4VoUqEVyhsPhzPPMsM+SZ+yqEGo4vGBiyedFLliq1URO
S8Od1IpNZC46WHU7k5bh71xbl6/YWEg1ZaUVGZtow6ZCiSigJywVxsmJTLkTzIh/lMI6Cx1JpSYT
E6mkX22dLixzMwE1ea4XpDWXSliWzvQ9fckJe3/18RR7qz0HDV5YZJ2ERnd2dnqsk9z0L9+dnV+c
0tevp5eful2afNkxKqNNT5fOcHb19u+ng1t2/u708vb87Pz0hkk10d3kmZbZiI65LY3xhOasSMlW
mlZiMcKQ9UfRdH7YjhM99hlbSDfzB9t9IZaOhnaZLioXYQIqdjV8b23Olq8P/7bLSidz6VYHTPG5
YDNhhFcQ96dNHIfj4JQg/qUDsYcT3JyDGiyBJ71ROFRjkAzHwPN+7oRRMPFB5NiEjOdtlrsZd2zG
LdMqX7VvIxWTDsEAc9jXHt0JL3P3rTK1s58kX2tnsW/krs+ILK4YzzKaYFfn77waf0oKITJnvGJ7
Kd9jXGVsD5GzR5HXhwRnVvrghBji4z64nY7pEFzY5Kh31DnunHReUUAHZeFk4Ui2HFsnXekP2SZ/
3Pv1X5Wqf3ded97A5J/wB15IOc4fHTRKOe5i0B/F750dyghR+Y/WRg/+tO3Xm9E1ZNL4jHmZibke
9Gn/z/4GxIMwK/iEEs6ye1G4hLLYx86vkHoZv6r1FJfS2hL572cYx2AQM/kobhMETd4uZvK1UMYd
H3MrKiGpMrHsuKWDZDXH/GAEJIotv7HfK0phsDazOnSR8zQEGEWdn+4kSQOhajs5DXYKMWfxVgb9
JpIlVhjJ8/pc4ZNVV5iWxgjlWBxW5XwsTOIPv3ZE0L4lMbi5SAojH7DH6F6squVxCHZhkASDVByG
21Zr2NsS6RgkEHap1tKnnkebvAOThBBn1MCIHnLGeJdW9vlJV6EK5S3+oQukRRFWG7ATF3A6T4dd
aie67FI4m/KCcnE+LxX5ERdByC4IXdinY1ptocvqAKQeS+dzbIwQ0aUjSKiuEtpzwR8ItT4d+W0g
SOG2cYw4kNQ5l/EVjZ+8eb1DR5vpBcs1YaiO17ui8FinKMUvRCBxuCkwFlgnEEfLcGmVxDyD+nkW
1C9mMp3hKyJxB1crEBMPFGdK+yX3QhSs4JbI890l0yZDzKgpubTPJojSTE4myBaFwF3wFdGFLUQK
Qyk9yRyAocy58bcRCZbZmS7zDJbqeyg6g5/dqqAgPvDLcmnJpdw5I8cloI7NS0iNI8WAcA487NJX
oCmeQw8N2bIocklML0WehVT/TsKeKLov9pNC5zJdUaSHX6M5d+ksqewIuRSmAEnNNQClVJfKmdUl
TCANQdQ6BO6VuTb6QcIPfrKa02bKlfynZ6wnJ3h+hxIjTtcHotiKQhiuDpYIEFkOnsFVecSr1zdO
sMdVAMi96iS4LheittASiQw2c5L8uNJl8C45nfEcQJemgDk+BhXt6fF3YPwecQ8uCGhUe6Ta4bFT
aoPa/VJP5zrlVEI8kmvxWevcz3LbzyEvxHaDPMcy8NHR4fGrehA46BmeYg9wF7ESRAe+V9NS2pnI
RiqcB+pGjyeSdU7sxEXrkRacfDghGv8LjLQiR9bKqYoESZF0jZRfINutp6MGkFsqcpUGWRFWKAoq
sUIBicAZE+LreeFCoQ0tUhWlGxVRF+tRxWAEVcaAy/apqu62gogayWLvgwnCzKUj1dYZX1b6gKST
IcUpzS3VBaCzcLOYSmpm7bJryPiYHnrpA3b75qj6+fbjdfhJGF3cy+UOaxHYWFW6ye9UcXZ93cnu
bs9+D5PUO8A9c5Rwpk1LvS17rvRaJxjGNLXsk5qP/eGH7hf8gR+QKP5w3h8PPC99o/O5f3N5fvlH
t+ZneCCQHHB4TWiG2xlR2JPbBVKrO4RY+vuuIOW+EP0lCW4feQN61RHpuigIG+W2DzpKhkbUPSbe
lrYrCUnUEvXbGEN1afhmNMCeH4NsERuga52J/ebidfXaY/27jZm5VF7V8eYoX8bRVvzCzJCGyYHV
RDRiUiIHyNz9NsnaECjQc/HCa0m2QBCTF3EgKhWImRSfaFIOO4+AEeuvGmNNGeQhIHq/Raphybmi
Lks49llmU2qSrrHxhfON6CL0QFksdoAwaKOo5qHkV0JkSEWlzRyUsfLE+uyo1cChQHOT/aWdLdIN
Qz9rg3oBVgr0ZuO1mU/QwZZfkDc01dg2di7Ytl3Deutkg1B85NFnQ9efV3c38d7XS+s4evMq2eIe
DJ7SAIsjG9NBrsdeHdIdDE9v0ZCfeBn8XidTVR+fVEnTqJWQLDNcilBTUaG4j35WD7MKdh+vDFmB
/dumgmnHMK1USP4ydaURWeXxvqpJtbpW7xYysarXQ3sNXLAbyEDwDWhARC1mQoW+mgiJGCCiQ6dm
hqnGIfkU7TwKlusP518YsCIT4SWGwtQiv1DEWYpd3LovC2nI6olbYKuAWaWEv0NsEyI9oJsGXyEf
QGyEP5BjAqJARbMBV5ysGvRhEDo9mQ40+QLWONsb9Ltn/YvhKdn6vuYl2js+WNn4ngKtHPeAD2UH
0H0LMuuw80lMMR2ojsqu2MNUm1NKjsX6Masuw34TSyrbfmOhZPPu82TVeA+7+hBlGL2h+UrfeL6q
bfCRFiaqehKrN1Vu2OP9t/DVfDRrUyHoANIkWekLmMFSVGUgrJpz6BpWBZTm2/Jh5QHzaZLEOp/O
0XwHUGleZvRr09buD5UdNG273bSCKmSUO3f+nrzXKpMbx6ez1ouIFNWNKGCHR5MD9EYAVZ4PsQOn
VDmgxacqlQWKFuob632r+gncV+R8JSgUawLfq/tMX6SP9bKT4FBhyN/YbvUu+kd424T8YG3lri/o
KFGMCIoyHurAGTdzBKWv6YILw87UBjSOiaLGlt6vH8TqPKMqEu2V6c1QVySoD2bagKI253BSmR34
9xPT5Tl6Q7uu7Vw5mZCvya9Rcz/3wOsvN0hhhOCDfHw+L7TxpWa4OAILQkua25Tv+fluqosVbTfA
v9UKFIMOc1Ts1Bt4kWhklIFn+Y14AA2Tj+7Co8jMuaL78uVisehkml4S6Z+XKX8RH0pI7C23Asvp
54Z8GFBiAXoJXwN+7Zuo+Dm0+dCn3GVEy1hAffvBw0Vr/bSNR4ze7yIi/X9h+jV0EmTSpk0hM6qc
GfSTJ2INOPR0CP0whmLwPBFKlDvU2W9u2eCBsdH3oJQK+xsPOik2jHizpiJEVIsXq6UHcCd4jxhk
qKlCqqoj4iLBgX3tV+BlIITjBeTvboNedOTmM16HvdcLQjnAGdWZIAcCCupSDIaVr8ga/7tBzKT8
K7Hv6V40eroqVgK/jClcnqFonrith6stREtvLigsfEQQogwjWFIJy+ZyOoNFXMWXBZ5bvY231ub0
quOzkqIDuRxwZjORCXSqNOW583VDF4fRSHnTFk8/TPyY9yFi/su0Z+9Ob9hMLMH5aCI8k0x8CVCF
Rhde8xEkloV/RabO7xdqZcffexDuHh53D0+S6vWYnk72yNcccAdQ42hy6Yp9lRNICmv/1KWndLpN
pnHThkpc7p8tgHhYut4fyx8VHOvIJPu7J4cwoXt4RH/Pziht4wtjwJLBzcVmqLMr6l433OIBuD0f
0Xze0zwQFSqEJ4rwtPlD3/7vyf0fHEZoFOobAAA=
"@;

    $DecodedBytes = [Convert]::FromBase64String($Encoded);
    $DecodedStream = New-Object IO.MemoryStream( , $DecodedBytes);

    $OutputStream = New-Object IO.FileStream( , $Path, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::Write);
    $GzipStream = New-Object IO.Compression.GzipStream $DecodedStream, ([IO.Compression.CompressionMode]::Decompress);
    $GzipStream.CopyTo( $OutputStream );

    $GzipStream.Close();
    $OutputStream.Close();
    $DecodedStream.Close();
}

EnsureDirectoryExists $CaddyHome;

if (MissingExecutable $CaddyExe) {
    Echo "Caddy is missing, downloading...";
    EnsureDirectoryExists $TempPath;
    GetFile -Url $CaddySource -Dest "$TempPath\caddy.zip";
    Unzip -Archive "$TempPath\caddy.zip" -Dest "$TempPath\caddy";
    Move "$TempPath\caddy\caddy.exe" $CaddyExe;
}

Cd $CaddyHome | Out-Null;

if (!(Test-Path -PathType Leaf -Path "$KeysDir\server.key") -Or !(Test-Path -PathType Leaf -Path "$KeysDir\server.crt"))
{
    Echo "Key missing";
    EnsureOpenSSLPresent;
    CreateOpenSSLConfig;
    EnsureDirectoryExists $KeysDir;
    Invoke-Expression "$OpenSSLExe req -x509 -nodes -days 365 -newkey rsa:2048 -keyout `"$KeysDir\server.key`" -out `"$KeysDir\server.crt`" -subj `"$CertSubject`"";
} else {
    Echo "Key found";
}

if ($args[0] -match "^[\d\.]+$")
{
    $ProxyPort = $args[0];
}
Echo "Will be listening on $ProxyPort";

if ($args[1] -match "^[\d\.]+$")
{
    $TargetPort = $args[1];
}
Echo "Will connect to $TargetPort";

$CaddyConfig = @"
0.0.0.0:$ProxyPort {
  log stdout
  errors stderr
  tls ./keys/server.crt ./keys/server.key
  proxy / http://localhost:$TargetPort {
    transparent
    header_upstream X-Forwarded-Port $ProxyPort
  }
}
"@;

Echo "Writing Caddyfile";
[IO.File]::WriteAllLines("$CaddyHome\Caddyfile.$ProxyPort", $CaddyConfig);
Invoke-Expression "$CaddyExe -conf Caddyfile.$ProxyPort";