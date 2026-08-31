$ErrorActionPreference = "Stop"

$realmPath = Join-Path $PSScriptRoot "keycloak/identity-os-realm.json"
if (-not (Test-Path $realmPath)) {
    throw "Realm export not found: $realmPath"
}

$realm = Get-Content $realmPath -Raw | ConvertFrom-Json
$requiredClients = @("identity-os-frontend", "identity-os-app-users", "admin-cli")
$requiredRoles = @("ORGANISATION_ADMIN", "APPLICATION_USER")
$requiredAppUserMappers = @("realm roles", "organization id", "application id", "external username")

foreach ($clientId in $requiredClients) {
    if (-not ($realm.clients | Where-Object { $_.clientId -eq $clientId })) {
        throw "Missing Keycloak client: $clientId"
    }
}

foreach ($roleName in $requiredRoles) {
    if (-not ($realm.roles.realm | Where-Object { $_.name -eq $roleName })) {
        throw "Missing realm role: $roleName"
    }
}

$appUsersClient = $realm.clients | Where-Object { $_.clientId -eq "identity-os-app-users" } | Select-Object -First 1
if (-not $appUsersClient.directAccessGrantsEnabled) {
    throw "identity-os-app-users must have directAccessGrantsEnabled=true"
}
if (-not $appUsersClient.publicClient) {
    throw "identity-os-app-users must be a public client for local password-grant testing"
}

foreach ($mapperName in $requiredAppUserMappers) {
    if (-not ($appUsersClient.protocolMappers | Where-Object { $_.name -eq $mapperName })) {
        throw "identity-os-app-users missing protocol mapper: $mapperName"
    }
}

if (-not $realm.smtpServer -or [string]::IsNullOrWhiteSpace($realm.smtpServer.from)) {
    throw "Realm SMTP sender is missing. Configure smtpServer.from for Keycloak action emails."
}
if ([string]::IsNullOrWhiteSpace($realm.smtpServer.host) -or [string]::IsNullOrWhiteSpace($realm.smtpServer.port)) {
    throw "Realm SMTP host/port is missing. Configure Mailpit SMTP settings."
}

Write-Host "Identity OS Keycloak realm export is valid." -ForegroundColor Green
Write-Host "Realm: $($realm.realm)"
Write-Host "Clients: $($requiredClients -join ', ')"
Write-Host "Roles: $($requiredRoles -join ', ')"
Write-Host "SMTP: $($realm.smtpServer.from) via $($realm.smtpServer.host):$($realm.smtpServer.port)"
