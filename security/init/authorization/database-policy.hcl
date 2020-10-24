# Policy lifted from: https://learn.hashicorp.com/tutorials/vault/database-root-rotation

path "sys/mounts/*"
{
  capabilities = [ "create", "read", "update", "delete", "list" ]
}

path "database/*" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}