
output "lanchonete_vpc_id" {
  value = module.lanchonete_vpc.vpc_id
}

output "lanchonete_rds_security_group_id" {
  value = module.lanchonete_rds_sg.security_group_id
}

output "lanchonete_subnet_id" {
  value = module.lanchonete_subnet.subnet_id
}

output "lanchonete_rds_endpoint" {
  value = module.lanchonete_rds.rds_endpoint
}
