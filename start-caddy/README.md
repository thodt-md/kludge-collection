## start-caddy

### Description

A family of cross-platform(ish), more or less self-contained Caddy reverse proxy launchers.

The launchers download and unpack Caddy if needed, generate self-signed keys using OpenSSL
(downloaded for Windows if needed), write a config for the proxy port and start Caddy with
the generated config.

The launchers support multiple proxy/target configurations with the same key.

OpenSSL is expected to be redundant/obsolete (see https://github.com/mholt/caddy/issues/1509).

### Requirements

*   Windows:
    * PowerShell 3.0 or newer
    * .NET 4.5.1 or newer

*   Linux:
    * OpenSSL 1.0.f or newer
    * GNU Wget
    * GNU Tar / Gzip
