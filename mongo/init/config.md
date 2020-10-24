```bash
# Convert all JSON to POSIX conformant multi-lines.

# Enable the Vault database secrets engine.
curl \
--header "X-Vault-Token: The_Token_Goes_Here" \
--request "POST" \
--data '{"type":"database"}' \
https://truth_src:8200/v1/sys/mounts/database

# Create the config data for MongoDB (root credential).
# Convert to POSIX conformant multi-line.
tee init-mongo.json <<EOF
{
  "plugin_name": "mongodb-database-plugin",
  "connection_url": "mongodb://{{username}}:{{password}}@mongo_svc:27017/admin?tls=true",
  "allowed_roles": "mongo-admin",
  "username": "vault-su",
  "password": "vault-seed-password!"
}
EOF

# Write the config to Vault to create our MongoDB root user.
curl \
--header "X-Vault-Token: The_Token_Goes_Here" \
--request "POST" \
--data @init-mongo.json \
https://truth_src:8200/v1/database/config/init

# Create the role data.
# Convert to POSIX conformant multi-line.
tee init-role.json <<EOF
{
  "db_name": "init",
  "creation_statements": '{ "db": "admin", "roles": [{ "role": "root" }, { "role": "readWriteAnyDatabase" }] }',
  "default_ttl": "1h",
  "max_ttl": "24h"
}
EOF

# Write the role data to Vault to map a MongoDB command to the role name.
curl \
--header "X-Vault-Token: The_Token_Goes_Here" \
--request "POST" \
--data @init-role.json \
https://truth_src:8200/v1/database/roles/mongo-admin

# Rotate root credentials immediately.
curl \
--header "X-Vault-Token: The_Token_Goes_Here" \
--request "POST" \
https://truth_src:8200/v1/database/rotate-root/init

# Create new role data for each micro service.
tee init-service.json <<EOF
{
  "the_data": "goes_in_here"
}
EOF

# Write the new role data to Vault.
curl \
--header "X-Vault-Token: The_Token_Goes_Here" \
--request "POST" \
--data @init-service.json \
https://truth_src:8200/v1/database/roles/service-role

# Generate new credentials.
curl \
--header "X-Vault-Token: The_Token_Goes_Here" \
--request "GET" \
https://truth_src:8200/v1/database/creds/service-role | jq

# The returned object will contain:
#   - "response.data.username",
#   - "response.data.password"
#
# Use these credentials to log in and confirm that they work.

# How to get the Admin Token for a service.
ADMIN_TOKEN=$(curl \
--request "POST" \
--header "X-Vault-Token: $VAULT_TOKEN" \
--data '{ "policies":"admin" }' \
$VAULT_ADDR/v1/auth/token/create | jq -r ".auth.client_token")
```
