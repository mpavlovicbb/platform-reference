output "substrate" {
  description = "Contract outputs consumed by the Cluster API manifests"
  value = {
    network_id     = module.substrate.network_id
    subnet_ids     = module.substrate.subnet_ids
    object_store   = module.substrate.object_store
    resource_group = module.substrate.resource_group
  }
}
