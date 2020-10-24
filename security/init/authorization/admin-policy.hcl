# Admin policy lifted from: https://learn.hashicorp.com/tutorials/vault/policies

# Health Check ---

path "sys/health"
{
  capabilities = [ "read", "sudo" ]
}

# ACL ---

path "sys/policies/acl"
{
  capabilities = [ "list" ]
}

path "sys/policies/acl/*"
{
  capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}

# Auth ---

path "auth/*"
{
  capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}

path "sys/auth"
{
  capabilities = [ "read" ]
}

path "sys/auth*"
{
  capabilities = [ "create", "update", "delete", "sudo" ]
}

# Engines ---

path "sys/mounts"
{
  capabilities = [ "read" ]
}

path "sys/mounts/*"
{
  capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}

path "database/*" {
  capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}

path "secret/*"
{
  capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}