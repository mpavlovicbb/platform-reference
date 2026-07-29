output "network_id" {
  description = "Contract: VPC id for CAPA AWSCluster.spec.network"
  value       = aws_vpc.this.id
}

output "subnet_ids" {
  description = "Contract: private node subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "Public subnets for load balancers"
  value       = aws_subnet.public[*].id
}

output "object_store" {
  description = "Contract: S3 bucket for Loki and backups"
  value       = aws_s3_bucket.objects.id
}

output "ssh_key_ref" {
  description = "Contract: CAPA manages instance keys via its own bastion/SSM model"
  value       = null
}
