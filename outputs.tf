/* VPC resource outputs */
output "vpc_id"         { value = aws_vpc.main.id }
output "vpc_main_rt_id" { value = aws_vpc.main.main_route_table_id }
output "vpc_cidr_block" { value = aws_vpc.main.cidr_block }

/* Subnet resource outputs */
output "prvt_subnet_id"     { value = aws_subnet.private.*.id }
output "prvt_subnet_arn"    { value = aws_subnet.private.*.arn }
output "prvt_subnet_cidr"   { value = aws_subnet.private.*.cidr_block }
output "public_subnet_id"   { value = aws_subnet.public.*.id }
output "public_subnet_arn"  { value = aws_subnet.public.*.arn }
output "public_subnet_cidr" { value = aws_subnet.public.*.cidr_block }

/* EKS resource output */

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane."
  value       = module.eks.cluster_security_group_id
}

#output "kubectl_config" {
#  description = "kubectl config as generated by the module."
#  value       = module.eks.kubeconfig
#}


output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = var.cluster_name
}


