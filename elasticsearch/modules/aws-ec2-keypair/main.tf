
#########
# Labels
########
module "label" {
  source     = "../labels"
  namespace  = var.namespace
  name       = var.name
  delimiter  = var.delimiter
  attributes = var.attributes
  tags       = var.tags
  enabled    = var.enabled
}

resource "aws_key_pair" "keypair" {
  key_name   = var.key-name
  public_key = var.public-key
}
