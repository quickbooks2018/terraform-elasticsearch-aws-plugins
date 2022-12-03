output "vpc-id" {
  value = module.vpc.vpc_id
}

output "public-subnet-ids" {
  value = module.vpc.public_subnets
}

output "private-subnets-ids" {
  value = module.vpc.private_subnets
}