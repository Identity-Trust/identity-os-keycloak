# Identity OS Keycloak

This project provides a repeatable local Keycloak setup for Identity OS.

## What Is Included

- Realm: `identity-os`
- Frontend/admin UI client: `identity-os-frontend`
- Third-party app-user token client: `identity-os-app-users`
- Roles:
  - `ORGANISATION_ADMIN`
  - `APPLICATION_USER`
- Token mappers for app users:
  - realm roles
  - `organization_id`
  - `application_id`
  - `external_username`

## Start Keycloak

Copy the example environment file if you want to override defaults:

```bash
cp .env.example .env
```

On Windows PowerShell:

```powershell
Copy-Item .env.example .env
```

Validate the committed realm export:

```powershell
.\validate-realm.ps1
```

Start Mailpit from the parent backend folder:

```powershell
cd ..
docker compose -f docker-compose.mailpit.yml up -d
cd identity-os-keycloak
```

Start Keycloak:

```bash
docker compose up -d
```

Open:

```text
http://localhost:8085
```

Default local admin:

```text
username: admin
password: admin
```

## Important Import Note

Keycloak imports `keycloak/identity-os-realm.json` only when the realm does not already exist in the mounted Docker volume.

If you change the realm export and need a clean local import, remove the container and volume, then start again:

```bash
docker compose down -v
docker compose up -d
```

This deletes local Keycloak data for this compose project.

## Email Configuration

The realm export is configured to send Keycloak action emails through Mailpit:

```text
SMTP host: host.docker.internal
SMTP port: 1025
From: no-reply@identity-os.local
Auth: off
TLS/SSL: off
```

Mailpit UI:

```text
http://localhost:8025
```

If Keycloak shows this error:

```text
Invalid sender address 'null'
```

then the realm was imported before SMTP settings were added, or the current realm has no `From` email address.

Fix option 1, clean local setup:

```powershell
docker compose down -v
cd ..
docker compose -f docker-compose.mailpit.yml up -d
cd identity-os-keycloak
docker compose up -d
```

Fix option 2, manual Keycloak UI:

Open `http://localhost:8085`, switch to realm `identity-os`, then go to:

```text
Realm settings -> Email
```

Set:

```text
From: no-reply@identity-os.local
Host: host.docker.internal
Port: 1025
Authentication: Off
Enable SSL: Off
Enable StartTLS: Off
```

Then click `Test connection`.

## Identity OS Service Configuration

Use these values in the onboarding service:

```env
KEYCLOAK_URL=http://localhost:8085
KEYCLOAK_TARGET_REALM=identity-os
KEYCLOAK_ADMIN_REALM=master
KEYCLOAK_ADMIN_CLIENT_ID=admin-cli
KEYCLOAK_ADMIN_USERNAME=admin
KEYCLOAK_ADMIN_PASSWORD=admin
KEYCLOAK_USER_CLIENT_ID=identity-os-app-users
```

Use these values in the frontend:

```env
NEXT_PUBLIC_KEYCLOAK_URL=http://localhost:8085
NEXT_PUBLIC_KEYCLOAK_REALM=identity-os
NEXT_PUBLIC_KEYCLOAK_CLIENT_ID=identity-os-frontend
NEXT_PUBLIC_API_BASE_URL=http://localhost:8080
NEXT_PUBLIC_ONBOARDING_API_BASE_URL=http://localhost:8081
```

Use this issuer URI in the API gateway:

```text
http://localhost:8085/realms/identity-os
```

## Refresh Realm Export From A Running Keycloak

Do this only when you intentionally change realm clients, roles, mappers, or required profile settings.

Keycloak cannot export from the embedded H2 database while the same container is running. Stop Keycloak first:

```bash
docker compose stop keycloak
```

Then export from the stopped container:

```bash
docker compose run --rm keycloak export --realm identity-os --file /opt/keycloak/data/import/identity-os-realm.json --users same_file
```

Start Keycloak again:

```bash
docker compose up -d
```

Review the JSON before committing. Do not commit real production users, secrets, or passwords.

## Team Checklist

Before sharing this setup with another developer, confirm:

- `docker compose config` succeeds.
- `.\validate-realm.ps1` succeeds.
- `keycloak/identity-os-realm.json` contains `identity-os-app-users`.
- `identity-os-app-users` has direct access grants enabled.
- The onboarding service uses `KEYCLOAK_USER_CLIENT_ID=identity-os-app-users`.
- The frontend uses `NEXT_PUBLIC_KEYCLOAK_CLIENT_ID=identity-os-frontend`.
- The API gateway issuer is `http://localhost:8085/realms/identity-os`.

## Notes On Users

The current realm export includes only local/test users. Application users created while testing can be recreated by registering through Identity OS. Do not commit real customer or production users.
