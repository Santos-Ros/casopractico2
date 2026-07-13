resource "random_password" "db_password" {
  length  = 20
  special = false
}

resource "random_password" "web_auth_password" {
  length  = 16
  special = false
}